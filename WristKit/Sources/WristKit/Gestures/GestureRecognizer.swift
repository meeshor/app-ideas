import Foundation

/// Faza gestu, wspólna dla wszystkich recognizerów.
public enum GesturePhase: String, Sendable, Codable, CaseIterable {
    /// Ręka w ruchu, nic się nie dzieje.
    case idle
    /// Ręka nieruchoma, gotowa: zapamiętana poza odniesienia.
    case ready
    /// Zamach / naciąg (cofnięcie ręki).
    case windup
    /// Właściwy ruch (rzut, zwolnienie).
    case active
    /// Po zdarzeniu: krótka przerwa, żeby nie zliczyć jednego ruchu dwa razy.
    case cooldown
}

/// Lekki stan „na żywo” (np. siła naciągu w łuku lub procy), wysyłany ~20 Hz.
public struct LiveGestureState: Sendable, Hashable, Codable {
    public var phase: GesturePhase
    /// Znormalizowana intensywność 0…1 (znaczenie zależy od gestu).
    public var intensity: Double
    public var t: TimeInterval

    public init(phase: GesturePhase, intensity: Double, t: TimeInterval) {
        self.phase = phase
        self.intensity = intensity
        self.t = t
    }
}

/// Wynik przetworzenia próbki.
public enum GestureOutput<Event: Sendable>: Sendable {
    case phaseChanged(GesturePhase)
    case live(LiveGestureState)
    case event(Event)
}

extension GestureOutput: Equatable where Event: Equatable {}

/// Recognizer gestu: deterministyczna maszyna stanów karmiona próbkami.
///
/// Ten sam kod działa na zegarku (próbki z Core Motion) i w testach
/// (próbki z `MotionReplayer`).
public protocol GestureRecognizer: Sendable {
    associatedtype Event: Sendable

    var phase: GesturePhase { get }

    /// Przetwarza jedną próbkę. Próbki muszą przychodzić w kolejności rosnącego `t`.
    mutating func process(_ sample: MotionSample) -> [GestureOutput<Event>]

    /// Wraca do stanu początkowego (np. przy zmianie gracza).
    mutating func reset()
}
