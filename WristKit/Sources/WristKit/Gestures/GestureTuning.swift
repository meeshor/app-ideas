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

/// Progi gestu rzutu z nadgarstka (rzutki). Opis maszyny stanów: `FlickThrowRecognizer`.
public struct FlickTuning: Sendable, Hashable, Codable {
    public var stillness = StillnessTuning()
    /// DO STROJENIA: |prędkość kątowa|, od której z „ready” zaczyna się ruch rzutu
    /// (zamach w tył też się liczy), rad/s.
    public var startRotationRate: Double = 1.5
    /// DO STROJENIA: minimalny szczyt |prędkości kątowej| rzutu, rad/s.
    public var minPeakRotationRate: Double = 4.0
    /// DO STROJENIA: minimalny szczyt |przyspieszenia użytkownika|, g.
    public var minPeakAcceleration: Double = 1.2
    /// DO STROJENIA: puszczenie = prędkość kątowa spada poniżej tego ułamka szczytu.
    public var releaseDropRatio: Double = 0.5
    /// DO STROJENIA: jak długo ręka może prawie stać w fazie rzutu przed szczytem
    /// (zmiana kierunku między zamachem w tył a rzutem), zanim uznamy, że rzutu nie będzie, s.
    public var pauseTolerance: TimeInterval = 0.15
    /// DO STROJENIA: maks. czas fazy rzutu (z zamachem w tył), po którym ją porzucamy, s.
    public var maxActiveDuration: TimeInterval = 0.8
    /// DO STROJENIA: ile czasu po puszczeniu czekamy na „odbicie” (ruch w drugą stronę,
    /// jak przy machaniu albo drapaniu się), zanim uznamy rzut. Opóźnia zdarzenie, s.
    public var confirmWindow: TimeInterval = 0.2
    /// DO STROJENIA: odbicie = w oknie potwierdzenia prędkość kątowa **w przeciwną stronę**
    /// niż w szczycie przekracza ten ułamek szczytu. Wtedy to nie rzut, tylko ruch oscylacyjny.
    public var reboundRatio: Double = 0.6
    /// DO STROJENIA: maks. udział rotacji wokół przedramienia w szczycie |ω|.
    /// Czysty obrót przedramienia (np. przekręcenie klucza) to nie rzut.
    public var maxSpinShare: Double = 0.9
    /// DO STROJENIA: jak długo ręka może się lekko ruszać w „ready” (celowanie, poprawka chwytu),
    /// zanim wrócimy do „idle” i znów trzeba się zatrzymać, s.
    public var readyTimeout: TimeInterval = 1.0
    /// DO STROJENIA: minimalne wzniesienie przedramienia w pozie „ready”, rad. `nil` = bez progu.
    /// Odrzuca ruchy z ręką opuszczoną wzdłuż ciała. Włączyć dopiero po sprawdzeniu osi
    /// przedramienia na zegarku (`WristOrientation`), inaczej odrzuci wszystkie rzuty.
    public var minReadyElevation: Double?
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
