import Foundation

/// Recognizer rzutu wybrany rodzajem gestu: jeden typ dla aplikacji na zegarku,
/// która przełącza gry (rzutki, ręczna, …) bez znajomości konkretnych klas.
public enum ThrowRecognizer: GestureRecognizer {
    public typealias Event = ThrowEvent

    case flick(FlickThrowRecognizer)
    case overarm(OverarmThrowRecognizer)

    /// Recognizer dla gestu albo nil, gdy gest nie jest jeszcze obsługiwany.
    public init?(kind: ThrowKind, tuning: GestureTuning = .default, orientation: WristOrientation = WristOrientation()) {
        switch kind {
        case .flick: self = .flick(FlickThrowRecognizer(tuning: tuning.flick, orientation: orientation))
        case .overarm: self = .overarm(OverarmThrowRecognizer(tuning: tuning.overarm, orientation: orientation))
        case .swing, .pendulum: return nil
        }
    }

    public var kind: ThrowKind {
        switch self {
        case .flick: .flick
        case .overarm: .overarm
        }
    }

    public var phase: GesturePhase {
        switch self {
        case .flick(let r): r.phase
        case .overarm(let r): r.phase
        }
    }

    public var orientation: WristOrientation {
        get {
            switch self {
            case .flick(let r): r.orientation
            case .overarm(let r): r.orientation
            }
        }
        set {
            switch self {
            case .flick(var r):
                r.orientation = newValue
                self = .flick(r)
            case .overarm(var r):
                r.orientation = newValue
                self = .overarm(r)
            }
        }
    }

    /// Podmienia progi właściwe dla gestu.
    public mutating func apply(_ tuning: GestureTuning) {
        switch self {
        case .flick(var r):
            r.tuning = tuning.flick
            self = .flick(r)
        case .overarm(var r):
            r.tuning = tuning.overarm
            self = .overarm(r)
        }
    }

    public mutating func process(_ sample: MotionSample) -> [GestureOutput<ThrowEvent>] {
        switch self {
        case .flick(var r):
            let outputs = r.process(sample)
            self = .flick(r)
            return outputs
        case .overarm(var r):
            let outputs = r.process(sample)
            self = .overarm(r)
            return outputs
        }
    }

    public mutating func reset() {
        switch self {
        case .flick(var r):
            r.reset()
            self = .flick(r)
        case .overarm(var r):
            r.reset()
            self = .overarm(r)
        }
    }
}
