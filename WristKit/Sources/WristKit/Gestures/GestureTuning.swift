import Foundation

// ============================================================================
// DO STROJENIA
//
// Wszystkie progi i krzywe gestów w jednym miejscu. Wartości startowe to
// szacunki; stroimy je na nagraniach z prawdziwego zegarka (docs/tuning.md).
// `Codable`, żeby ekran debug mógł podmienić je na żywo bez przebudowy.
// ============================================================================

/// Progi wykrywania spoczynku ręki (wspólne dla gestów).
public struct StillnessTuning: Sendable, Hashable, Codable {
    /// DO STROJENIA: maks. |prędkość kątowa| uznawana za spoczynek, rad/s.
    public var maxRotationRate: Double = 0.6
    /// DO STROJENIA: maks. |przyspieszenie użytkownika| uznawane za spoczynek, g.
    public var maxUserAcceleration: Double = 0.08
    /// DO STROJENIA: jak długo ręka musi być nieruchoma, żeby przejść w „ready”, s.
    public var minDuration: TimeInterval = 0.25

    public init() {}
}

/// Progi gestu rzutu z nadgarstka (rzutki).
public struct FlickTuning: Sendable, Hashable, Codable {
    public var stillness = StillnessTuning()
    /// DO STROJENIA: minimalny szczyt |prędkości kątowej| rzutu, rad/s.
    public var minPeakRotationRate: Double = 4.0
    /// DO STROJENIA: minimalny szczyt |przyspieszenia użytkownika|, g.
    public var minPeakAcceleration: Double = 1.2
    /// DO STROJENIA: puszczenie = prędkość kątowa spada poniżej tego ułamka szczytu.
    public var releaseDropRatio: Double = 0.5
    /// DO STROJENIA: maks. czas fazy rzutu, po którym ją porzucamy, s.
    public var maxActiveDuration: TimeInterval = 0.4
    /// DO STROJENIA: przerwa po rzucie, s.
    public var cooldown: TimeInterval = 0.6
    /// DO STROJENIA: efektywne ramię dźwigni (łokieć → dłoń) do szacowania prędkości, m.
    public var leverArm: Double = 0.35
    /// DO STROJENIA: jerk (g/s), który mapujemy na 1.0 w `ThrowEvent.jerk`.
    public var jerkForUnit: Double = 60

    public init() {}
}

/// Komplet ustawień WristKit.
public struct GestureTuning: Sendable, Hashable, Codable {
    public var flick = FlickTuning()

    public init() {}

    public static let `default` = GestureTuning()
}
