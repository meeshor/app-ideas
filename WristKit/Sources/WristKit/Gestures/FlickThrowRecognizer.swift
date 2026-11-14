import Foundation

/// Rozpoznaje krótki rzut z nadgarstka (rzutki).
///
/// Maszyna stanów (progi w `FlickTuning`, wszystkie do strojenia):
///
/// ```
/// idle ──(ręka nieruchoma ≥ minDuration)──▶ ready  (zapamiętuje pozę odniesienia)
/// ready ──(|ω| > startRotationRate)──▶ active      (zamach w tył też tu wchodzi)
/// ready ──(lekki ruch dłużej niż readyTimeout)──▶ idle
/// active ──(szczyt |ω| i |a| ponad progi, potem |ω| < releaseDropRatio·szczyt)──▶ potwierdzanie
/// active ──(za słabo, pauza > pauseTolerance, za długo, sam obrót przedramienia)──▶ idle (bez zdarzenia)
/// potwierdzanie ──(brak odbicia przez confirmWindow)──▶ zdarzenie, cooldown
/// potwierdzanie ──(odbicie: obrót wstecz > reboundRatio·szczyt)──▶ idle (machanie, drapanie)
/// cooldown ──(po czasie)──▶ idle
/// ```
///
/// Chwila puszczenia = próbka ze szczytem |ω|. Z niej bierzemy kierunek (`ThrowGeometry`)
/// i `watchTimestamp`. Faza potwierdzania nie zmienia `phase` (zostaje `active`), a zdarzenie
/// wychodzi z opóźnieniem `confirmWindow` — przy rzutkach animacja lotu i tak trwa dłużej.
public struct FlickThrowRecognizer: GestureRecognizer {
    public typealias Event = ThrowEvent

    public var tuning: FlickTuning {
        didSet { stillness.tuning = tuning.stillness }
    }
    /// Orientacja zegarka aktywnego gracza (zmienia się przy pass & play).
    public var orientation: WristOrientation

    public private(set) var phase: GesturePhase = .idle

    private var stillness: StillnessDetector
    private var ready: ReadyPose?
    private var readyMovingSince: TimeInterval?
    private var throwState: ThrowState?
    private var pending: Pending?
    private var cooldownUntil: TimeInterval = 0

    /// Poza odniesienia z ostatniej chwili spoczynku.
    private struct ReadyPose: Sendable {
        var attitude: Quaternion
        var gravity: Vector3
    }

    /// Statystyki fazy rzutu.
    private struct ThrowState: Sendable {
        var start: TimeInterval
        var peakRate: Double = 0
        var peak: MotionSample
        var peakAcceleration: Double = 0
        var peakJerk: Double = 0
        var spinSum: Double = 0
        var spinCount = 0
        var previous: MotionSample
        /// Od kiedy ręka prawie stoi (przed szczytem), `nil` = w ruchu.
        var slowSince: TimeInterval?
    }

    /// Rzut czekający na potwierdzenie (brak odbicia).
    private struct Pending: Sendable {
        var event: ThrowEvent
        var releasedAt: TimeInterval
        var peakRate: Double
        /// Kierunek prędkości kątowej w szczycie (jednostkowy).
        var peakAxis: Vector3
    }

    public init(tuning: FlickTuning = FlickTuning(), orientation: WristOrientation = WristOrientation()) {
        self.tuning = tuning
        self.orientation = orientation
        self.stillness = StillnessDetector(tuning: tuning.stillness)
    }

    public mutating func reset() {
        phase = .idle
        stillness.reset()
        ready = nil
        readyMovingSince = nil
        throwState = nil
        pending = nil
        cooldownUntil = 0
    }

    public mutating func process(_ sample: MotionSample) -> [GestureOutput<ThrowEvent>] {
        switch phase {
        case .idle:
            return processIdle(sample)
        case .ready:
            return processReady(sample)
        case .windup, .active:
            return pending == nil ? processActive(sample) : processPending(sample)
        case .cooldown:
            guard sample.t >= cooldownUntil else { return [] }
            return transition(to: .idle)
        }
    }

    // MARK: - Fazy

    private mutating func processIdle(_ sample: MotionSample) -> [GestureOutput<ThrowEvent>] {
        guard stillness.process(sample), isReadyPoseAllowed(sample) else { return [] }
        ready = ReadyPose(attitude: sample.attitude, gravity: sample.gravity)
        readyMovingSince = nil
        return transition(to: .ready)
    }

    private mutating func processReady(_ sample: MotionSample) -> [GestureOutput<ThrowEvent>] {
        let rate = sample.rotationRate.length
        if rate > tuning.startRotationRate {
            throwState = ThrowState(start: sample.t, peak: sample, previous: sample)
            return transition(to: .active) + processActive(sample)
        }
        if stillness.isStill(sample) {
            // Poza odniesienia = ostatnia chwila spoczynku tuż przed rzutem.
            ready = ReadyPose(attitude: sample.attitude, gravity: sample.gravity)
            readyMovingSince = nil
            return []
        }
        let since = readyMovingSince ?? sample.t
        readyMovingSince = since
        if sample.t - since > tuning.readyTimeout {
            return abandon()
        }
        return []
    }

    private mutating func processActive(_ sample: MotionSample) -> [GestureOutput<ThrowEvent>] {
        guard var state = throwState else { return abandon() }
        let rate = sample.rotationRate.length
        let acceleration = sample.userAcceleration.length
        let axis = orientation.handAxis

        let dt = sample.t - state.previous.t
        if dt > 0 {
            let jerk = (sample.userAcceleration - state.previous.userAcceleration).length / dt
            state.peakJerk = max(state.peakJerk, jerk)
        }
        state.previous = sample
        state.peakAcceleration = max(state.peakAcceleration, acceleration)
        if rate > state.peakRate {
            state.peakRate = rate
            state.peak = sample
        }
        if rate < tuning.startRotationRate * 0.5 {
            state.slowSince = state.slowSince ?? sample.t
        } else {
            state.slowSince = nil
        }
        if rate >= tuning.startRotationRate {
            state.spinSum += sample.rotationRate.dot(axis)
            state.spinCount += 1
        }
        throwState = state

        if sample.t - state.start > tuning.maxActiveDuration {
            return abandon()
        }

        let peakReached = state.peakRate >= tuning.minPeakRotationRate
        if !peakReached {
            // Ruch wygasł, zanim osiągnął siłę rzutu (sam zamach w tył albo leniwy ruch).
            // Krótka pauza jest dozwolona: tak wygląda zmiana kierunku po zamachu w tył.
            if let slowSince = state.slowSince, sample.t - slowSince > tuning.pauseTolerance {
                return abandon()
            }
            return []
        }
        guard rate < state.peakRate * tuning.releaseDropRatio else { return [] }

        // Puszczenie: sprawdzamy, czy to w ogóle rzut.
        guard state.peakAcceleration >= tuning.minPeakAcceleration else { return abandon() }
        let peakSpin = abs(state.peak.rotationRate.dot(axis))
        guard peakSpin <= tuning.maxSpinShare * state.peakRate else { return abandon() }
        guard let ready else { return abandon() }

        let event = makeEvent(state: state, ready: ready)
        pending = Pending(
            event: event,
            releasedAt: sample.t,
            peakRate: state.peakRate,
            peakAxis: state.peak.rotationRate.normalized
        )
        return []
    }

    private mutating func processPending(_ sample: MotionSample) -> [GestureOutput<ThrowEvent>] {
        guard let pending else { return [] }
        // Odbicie = obrót w przeciwną stronę niż w szczycie (machanie, drapanie).
        // Drgania w tę samą stronę (szarpnięty rzut, wybrzmienie) się nie liczą.
        if -sample.rotationRate.dot(pending.peakAxis) > pending.peakRate * tuning.reboundRatio {
            return abandon()
        }
        guard sample.t - pending.releasedAt >= tuning.confirmWindow else { return [] }
        self.pending = nil
        throwState = nil
        cooldownUntil = sample.t + tuning.cooldown
        return [.event(pending.event)] + transition(to: .cooldown)
    }

    // MARK: - Pomocnicze

    private func makeEvent(state: ThrowState, ready: ReadyPose) -> ThrowEvent {
        let axis = orientation.handAxis
        let peak = state.peak
        let pitch = ThrowGeometry.elevation(of: axis, gravity: peak.gravity)
            - ThrowGeometry.elevation(of: axis, gravity: ready.gravity)
        let yaw = ThrowGeometry.yaw(
            axis: axis,
            readyAttitude: ready.attitude,
            readyGravity: ready.gravity,
            attitude: peak.attitude
        )
        let meanSpin = state.spinCount > 0 ? state.spinSum / Double(state.spinCount) : 0
        return ThrowEvent(
            kind: .flick,
            speed: state.peakRate * tuning.leverArm,
            pitch: pitch,
            yaw: yaw,
            spin: meanSpin * orientation.wrist.mirrorSign,
            jerk: state.peakJerk / tuning.jerkForUnit,
            watchTimestamp: peak.t
        )
    }

    private func isReadyPoseAllowed(_ sample: MotionSample) -> Bool {
        guard let minimum = tuning.minReadyElevation else { return true }
        return ThrowGeometry.elevation(of: orientation.handAxis, gravity: sample.gravity) >= minimum
    }

    private mutating func abandon() -> [GestureOutput<ThrowEvent>] {
        throwState = nil
        pending = nil
        ready = nil
        readyMovingSince = nil
        return transition(to: .idle)
    }

    private mutating func transition(to newPhase: GesturePhase) -> [GestureOutput<ThrowEvent>] {
        guard newPhase != phase else { return [] }
        phase = newPhase
        if newPhase == .idle || newPhase == .ready {
            stillness.reset()
        }
        return [.phaseChanged(newPhase)]
    }
}
