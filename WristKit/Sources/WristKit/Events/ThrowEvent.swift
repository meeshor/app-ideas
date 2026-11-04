import Foundation

/// Rodzaj gestu rzutu. Nowe gry dodają tu kolejne przypadki.
public enum ThrowKind: String, Sendable, Codable, CaseIterable, CodingKeyRepresentable {
    /// Krótki rzut z nadgarstka (rzutki).
    case flick
    /// Rzut z zamachem nad głową (ręczna), może być zwodem.
    case overarm
    /// Zamach (przyszłość: oszczep, kula, baseball).
    case swing
    /// Ruch wahadłowy (przyszłość: mini-golf).
    case pendulum
}

/// Rozpoznany rzut. Powstaje na zegarku i jest wysyłany na telefon.
///
/// Kąty są **względne do pozy „ready”** (ręka nieruchoma tuż przed rzutem)
/// i już zlustrzone dla lewej ręki, więc gra nie musi wiedzieć, na którym
/// nadgarstku jest zegarek.
public struct ThrowEvent: Sendable, Hashable, Codable, Identifiable {
    public var id: UUID
    public var kind: ThrowKind
    /// Szacunkowa prędkość w chwili puszczenia, m/s.
    public var speed: Double
    /// Kąt w pionie w radianach; dodatni = w górę.
    public var pitch: Double
    /// Kąt w poziomie w radianach; dodatni = w prawo.
    public var yaw: Double
    /// Rotacja wokół osi przedramienia w trakcie rzutu, rad/s (dodatnia = supinacja).
    public var spin: Double
    /// Znormalizowany szczyt jerku (zmiany przyspieszenia), 0 = gładko, ≥1 = mocne szarpnięcie.
    public var jerk: Double
    /// Zamach rozpoczęty i zatrzymany przed puszczeniem (tylko `overarm`).
    public var isFeint: Bool
    /// Chwila puszczenia według zegara zegarka (jak `MotionSample.t`).
    public var watchTimestamp: TimeInterval

    public init(
        id: UUID = UUID(),
        kind: ThrowKind,
        speed: Double,
        pitch: Double,
        yaw: Double,
        spin: Double = 0,
        jerk: Double = 0,
        isFeint: Bool = false,
        watchTimestamp: TimeInterval
    ) {
        self.id = id
        self.kind = kind
        self.speed = speed
        self.pitch = pitch
        self.yaw = yaw
        self.spin = spin
        self.jerk = jerk
        self.isFeint = isFeint
        self.watchTimestamp = watchTimestamp
    }
}
