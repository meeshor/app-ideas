import Foundation

/// Rozpoznaje rzut z zamachem nad głową (rzut karny w piłce ręcznej), także **zwód**.
///
/// ```
/// idle ──(ręka nieruchoma)──▶ ready (poza odniesienia)
/// ready ──(|ω| > startRotationRate)──▶ windup/active (zamach w tył i rzut w przód)
/// active ──(szczyt |ω| ≥ minPeak i |a| ≥ minAccel, potem |ω| < drop·szczyt)──▶ zdarzenie, cooldown
/// active ──(szczyt ≥ feintMinPeak, ale bez rzutu, a potem ręka stoi feintHold)──▶ zdarzenie isFeint, ready
/// active ──(za słabo albo za długo)──▶ idle
/// ```
///
/// Po zwodzie wracamy od razu do `ready` (bez cooldown) z nową pozą odniesienia,
/// bo prawdziwy rzut zwykle pada zaraz po zwodzie. Rzut nad głową ma długie „wybrzmienie”
/// ręki, więc nie czekamy na potwierdzenie jak w rzutkach.
public struct OverarmThrowRecognizer: GestureRecognizer {
    public typealias Event = ThrowEvent

    public var tuning: OverarmTuning {
        didSet { stillness.tuning = tuning.stillness }
    }
    public var orientation: WristOrientation

    public private(set) var phase: GesturePhase = .idle

    private var stillness: StillnessDetector
    private var ready: (attitude: Quaternion, gravity: Vector3)?
    private var motion: Motion?
    private var cooldownUntil: TimeInterval = 0

    private struct Motion: Sendable {
        var start: TimeInterval
        var peakRate: Double = 0
        var peak: MotionSample
        var peakAcceleration: Double = 0
        var peakJerk: Double = 0
        var previous: MotionSample
        var stillSince: TimeInterval?
    }

    public init(tuning: OverarmTuning = OverarmTuning(), orientation: WristOrientation = WristOrientation()) {
        self.tuning = tuning
        self.orientation = orientation
        self.stillness = StillnessDetector(tuning: tuning.stillness)
    }

    public mutating func reset() {
        phase = .idle
        stillness.reset()
        ready = nil
        motion = nil
        cooldownUntil = 0
    }

    public mutating func process(_ sample: MotionSample) -> [GestureOutput<ThrowEvent>] {
        switch phase {
        case .idle:
            guard stillness.process(sample) else { return [] }
            ready = (sample.attitude, sample.gravity)
            return transition(to: .ready)
        case .ready:
            if sample.rotationRate.length > tuning.startRotationRate {
                motion = Motion(start: sample.t, peak: sample, previous: sample)
                return transition(to: .windup) + processMotion(sample)
            }
            if stillness.isStill(sample) {
                ready = (sample.attitude, sample.gravity)
            }
            return []
        case .windup, .active:
            return processMotion(sample)
        case .cooldown:
            guard sample.t >= cooldownUntil else { return [] }
            return transition(to: .idle)
        }
    }

    private mutating func processMotion(_ sample: MotionSample) -> [GestureOutput<ThrowEvent>] {
        guard var state = motion else { return transition(to: .idle) }
        let rate = sample.rotationRate.length
        let dt = sample.t - state.previous.t
        if dt > 0 {
            state.peakJerk = max(state.peakJerk, (sample.userAcceleration - state.previous.userAcceleration).length / dt)
        }
        state.previous = sample
        state.peakAcceleration = max(state.peakAcceleration, sample.userAcceleration.length)
        if rate > state.peakRate {
            state.peakRate = rate
            state.peak = sample
        }
        state.stillSince = stillness.isStill(sample) ? (state.stillSince ?? sample.t) : nil
        motion = state

        var outputs: [GestureOutput<ThrowEvent>] = []
        if phase == .windup, state.peakRate >= tuning.feintMinPeakRotationRate {
            outputs += transition(to: .active)
        }

        // Rzut: mocny szczyt i spadek po nim.
        if state.peakRate >= tuning.minPeakRotationRate,
           state.peakAcceleration >= tuning.minPeakAcceleration,
           rate < state.peakRate * tuning.releaseDropRatio {
            let event = makeEvent(state, isFeint: false)
            motion = nil
            cooldownUntil = sample.t + tuning.cooldown
            return outputs + [.event(event)] + transition(to: .cooldown)
        }

        // Zwód: ruch zaczęty (ponad próg zwodu), ale ręka znów stoi.
        if let stillSince = state.stillSince, sample.t - stillSince >= tuning.feintHold {
            motion = nil
            if state.peakRate >= tuning.feintMinPeakRotationRate {
                let event = makeEvent(state, isFeint: true)
                ready = (sample.attitude, sample.gravity)
                return outputs + [.event(event)] + transition(to: .ready)
            }
            ready = (sample.attitude, sample.gravity)
            return outputs + transition(to: .ready)
        }

        if sample.t - state.start > tuning.maxActiveDuration {
            motion = nil
            return outputs + transition(to: .idle)
        }
        return outputs
    }

    /// DO SPRAWDZENIA NA ZEGARKU: przy pionowym przedramieniu „przód” = −z (tarcza do gracza).
    static let fallbackForward = Vector3(0, 0, -1)

    private func makeEvent(_ state: Motion, isFeint: Bool) -> ThrowEvent {
        let axis = orientation.handAxis
        let reference = ready ?? (state.peak.attitude, state.peak.gravity)
        let pitch = ThrowGeometry.elevation(of: axis, gravity: state.peak.gravity)
            - ThrowGeometry.elevation(of: axis, gravity: reference.gravity)
        let yaw = ThrowGeometry.yaw(
            axis: axis,
            readyAttitude: reference.attitude,
            readyGravity: reference.gravity,
            attitude: state.peak.attitude,
            fallbackForward: Self.fallbackForward
        )
        // Skręt w chwili szczytu: zamach w tył (bez skrętu) nie rozmywa „wkrętki”.
        let spin = state.peak.rotationRate.dot(axis)
        return ThrowEvent(
            kind: .overarm,
            speed: state.peakRate * tuning.leverArm,
            pitch: pitch,
            yaw: yaw,
            spin: spin * orientation.wrist.mirrorSign,
            jerk: state.peakJerk / tuning.jerkForUnit,
            isFeint: isFeint,
            watchTimestamp: state.peak.t
        )
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
