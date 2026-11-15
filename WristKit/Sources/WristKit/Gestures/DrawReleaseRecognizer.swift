import Foundation

/// Faza łuku (szczegółowo; ogólna `GesturePhase` też jest raportowana).
public enum DrawPhase: String, Sendable, Codable, CaseIterable {
    case idle
    /// Przedramię uniesione (gotowość do naciągu).
    case raised
    case drawing
    /// Kotwica: ręka stoi przy twarzy, liczymy stabilność.
    case anchored
    case released
    case cancelled

    /// Odpowiednik w ogólnych fazach gestu.
    public var gesturePhase: GesturePhase {
        switch self {
        case .idle, .cancelled: .idle
        case .raised: .ready
        case .drawing: .windup
        case .anchored: .active
        case .released: .cooldown
        }
    }
}

/// Strzał: wszystko, czego gra potrzebuje do balistyki i feedbacku.
public struct ShotRelease: Sendable, Hashable, Codable {
    /// Siła naciągu 0…1 (z impulsu fazy naciągania, z limitem).
    public var strength: Double
    /// RMS |ω| w ostatnim oknie kotwicy, rad/s (mniej = stabilniej).
    public var stability: Double
    /// Czas trzymania w kotwicy, s.
    public var holdTime: TimeInterval
    /// Tętno w chwili strzału (uzupełnia aplikacja na zegarku z HealthKit), bpm.
    public var heartRate: Double?
    public var watchTimestamp: TimeInterval

    public init(strength: Double, stability: Double, holdTime: TimeInterval, heartRate: Double? = nil, watchTimestamp: TimeInterval) {
        self.strength = strength
        self.stability = stability
        self.holdTime = holdTime
        self.heartRate = heartRate
        self.watchTimestamp = watchTimestamp
    }
}

/// Zdarzenia łuku wysyłane z zegarka na telefon.
public enum DrawEvent: Sendable, Hashable, Codable {
    case drawStarted(strength: Double)
    case anchored(stability: Double)
    /// Podgląd ~20 Hz w kotwicy: bieżąca stabilność i czas trzymania (kołysanie celownika na żywo).
    case holding(stability: Double, holdTime: TimeInterval)
    case released(ShotRelease)
    case cancelled
}

/// Rozpoznaje naciąg i puszczenie cięciwy (zegarek na ręce **naciągającej**).
///
/// ```
/// idle ──(oś dłoni powyżej raisedMinElevation)──▶ raised
/// raised ──(przyspieszenie w tył wzdłuż przedramienia)──▶ drawing  (impuls → siła)
/// drawing ──(spoczynek ≥ anchorMinDuration, siła ≥ min)──▶ anchored (RMS ω → stabilność)
/// anchored ──(skok |a| albo |ω|)──▶ released → idle
/// raised/drawing/anchored ──(ręka opada albo za długo / brak naciągu)──▶ cancelled → idle
/// ```
///
/// Siła to impuls (∑ a·dt) dodatnich przyspieszeń w tył, a nie całkowana pozycja (dryf).
public struct DrawReleaseRecognizer: GestureRecognizer {
    public typealias Event = DrawEvent

    public var tuning: DrawTuning
    public var orientation: WristOrientation

    public private(set) var drawPhase: DrawPhase = .idle
    public var phase: GesturePhase { drawPhase.gesturePhase }

    private var impulse = 0.0
    private var stillSince: TimeInterval?
    private var anchoredAt: TimeInterval = 0
    private var window: [(t: TimeInterval, rate: Double)] = []
    private var sampleCounter = 0
    private var previousT: TimeInterval?
    private var finishedAt: TimeInterval = -.infinity

    public init(tuning: DrawTuning = DrawTuning(), orientation: WristOrientation = WristOrientation()) {
        self.tuning = tuning
        self.orientation = orientation
    }

    public var strength: Double { min(1, impulse / tuning.fullDrawImpulse) }

    public mutating func reset() {
        drawPhase = .idle
        impulse = 0
        stillSince = nil
        window = []
        sampleCounter = 0
        previousT = nil
        finishedAt = -.infinity
    }

    public mutating func process(_ sample: MotionSample) -> [GestureOutput<DrawEvent>] {
        let dt = previousT.map { max(0, sample.t - $0) } ?? 0
        previousT = sample.t
        let axis = orientation.handAxis
        let elevation = ThrowGeometry.elevation(of: axis, gravity: sample.gravity)
        let backward = -sample.userAcceleration.dot(axis)
        let still = sample.rotationRate.length <= tuning.anchorMaxRotationRate
            && sample.userAcceleration.length <= tuning.anchorMaxAcceleration
        let lowered = elevation < tuning.raisedMinElevation - tuning.lowerHysteresis

        switch drawPhase {
        case .idle, .released, .cancelled:
            if drawPhase != .idle, sample.t - finishedAt < tuning.rearmDelay { return [] }
            guard elevation >= tuning.raisedMinElevation else {
                return drawPhase == .idle ? [] : transition(to: .idle)
            }
            impulse = 0
            return transition(to: .raised)

        case .raised:
            if lowered { return transition(to: .idle) }
            if backward > tuning.drawAccelerationThreshold {
                impulse = backward * dt
                stillSince = nil
                return transition(to: .drawing)
            }
            return []

        case .drawing:
            if lowered { return cancel() }
            if backward > tuning.drawAccelerationThreshold { impulse += backward * dt }
            stillSince = still ? (stillSince ?? sample.t) : nil
            guard let since = stillSince, sample.t - since >= tuning.anchorMinDuration else { return [] }
            guard strength >= tuning.minDrawStrength else {
                // Ruch bez prawdziwego naciągu: wracamy do gotowości.
                impulse = 0
                return transition(to: .raised)
            }
            anchoredAt = since
            window = []
            sampleCounter = 0
            return [.event(.drawStarted(strength: strength))] + transition(to: .anchored)
                + [.event(.anchored(stability: 0))]

        case .anchored:
            if sample.userAcceleration.length > tuning.releaseAcceleration
                || sample.rotationRate.length > tuning.releaseRotationRate {
                let release = ShotRelease(
                    strength: strength,
                    stability: stabilityRMS(),
                    holdTime: sample.t - anchoredAt,
                    watchTimestamp: sample.t
                )
                finishedAt = sample.t
                return [.event(.released(release))] + transition(to: .released)
            }
            if lowered || sample.t - anchoredAt > tuning.maxAnchorDuration { return cancel() }
            window.append((sample.t, sample.rotationRate.length))
            window.removeAll { sample.t - $0.t > tuning.stabilityWindow }
            sampleCounter += 1
            if sampleCounter % max(1, tuning.liveEverySamples) == 0 {
                let stability = stabilityRMS()
                return [
                    .event(.holding(stability: stability, holdTime: sample.t - anchoredAt)),
                    .live(LiveGestureState(phase: .active, intensity: min(1, stability / tuning.anchorMaxRotationRate), t: sample.t))
                ]
            }
            return []
        }
    }

    /// RMS |ω| w oknie kotwicy (rad/s).
    private func stabilityRMS() -> Double {
        guard !window.isEmpty else { return 0 }
        let sum = window.reduce(0) { $0 + $1.rate * $1.rate }
        return (sum / Double(window.count)).squareRoot()
    }

    private mutating func cancel() -> [GestureOutput<DrawEvent>] {
        impulse = 0
        finishedAt = previousT ?? 0
        return [.event(.cancelled)] + transition(to: .cancelled)
    }

    private mutating func transition(to newPhase: DrawPhase) -> [GestureOutput<DrawEvent>] {
        let oldGeneral = drawPhase.gesturePhase
        drawPhase = newPhase
        return newPhase.gesturePhase == oldGeneral ? [] : [.phaseChanged(newPhase.gesturePhase)]
    }
}
