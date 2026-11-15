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

/// Progi rzutu z zamachem nad głową (piłka ręczna), ze zwodem. Opis: `OverarmThrowRecognizer`.
public struct OverarmTuning: Sendable, Hashable, Codable {
    public var stillness = StillnessTuning()
    /// DO STROJENIA: |ω|, od której z „ready” zaczyna się zamach, rad/s.
    public var startRotationRate: Double = 2.0
    /// DO STROJENIA: minimalny szczyt |ω| prawdziwego rzutu, rad/s.
    public var minPeakRotationRate: Double = 9.0
    /// DO STROJENIA: minimalny szczyt |a| prawdziwego rzutu, g.
    public var minPeakAcceleration: Double = 2.0
    /// DO STROJENIA: puszczenie = |ω| spada poniżej tego ułamka szczytu.
    public var releaseDropRatio: Double = 0.5
    /// DO STROJENIA: zwód = ruch, który osiągnął co najmniej tyle |ω|, ale nie stał się rzutem, rad/s.
    public var feintMinPeakRotationRate: Double = 3.0
    /// DO STROJENIA: zwód kończy się, gdy ręka stoi tak długo (spoczynek wg `stillness`), s.
    public var feintHold: TimeInterval = 0.12
    /// DO STROJENIA: maks. czas zamachu z rzutem albo zwodem, s.
    public var maxActiveDuration: TimeInterval = 1.5
    /// DO STROJENIA: przerwa po rzucie, s.
    public var cooldown: TimeInterval = 1.0
    /// DO STROJENIA: ramię dźwigni (bark → dłoń) do szacowania prędkości, m.
    public var leverArm: Double = 0.6
    /// DO STROJENIA: jerk (g/s), który mapujemy na 1.0.
    public var jerkForUnit: Double = 600

    public init() {}
}

/// Progi naciągu i puszczenia cięciwy (łucznictwo). Opis: `DrawReleaseRecognizer`.
public struct DrawTuning: Sendable, Hashable, Codable {
    /// DO STROJENIA: przedramię „uniesione”, gdy oś dłoni jest wyżej niż ten kąt, rad (−0,35 ≈ −20°).
    public var raisedMinElevation: Double = -0.35
    /// DO STROJENIA: histereza opuszczenia ręki (anulowanie), rad.
    public var lowerHysteresis: Double = 0.25
    /// DO STROJENIA: przyspieszenie w tył wzdłuż przedramienia, od którego liczymy naciąg, g.
    public var drawAccelerationThreshold: Double = 0.08
    /// DO STROJENIA: impuls fazy przyspieszania (g·s) odpowiadający pełnemu naciągowi (siła 1).
    public var fullDrawImpulse: Double = 0.1
    /// DO STROJENIA: minimalna siła, żeby uznać, że był naciąg (poniżej: ruch przypadkowy).
    public var minDrawStrength: Double = 0.2
    /// DO STROJENIA: kotwica = |ω| poniżej tego progu…, rad/s.
    public var anchorMaxRotationRate: Double = 0.6
    /// DO STROJENIA: … i |a| poniżej tego progu, g.
    public var anchorMaxAcceleration: Double = 0.12
    /// DO STROJENIA: … przez co najmniej tyle sekund (prompt: ≥ 300 ms).
    public var anchorMinDuration: TimeInterval = 0.3
    /// DO STROJENIA: okno RMS żyroskopu do miary stabilności, s (prompt: 0,5 s).
    public var stabilityWindow: TimeInterval = 0.5
    /// DO STROJENIA: puszczenie = skok |a| powyżej, g…
    public var releaseAcceleration: Double = 1.0
    /// DO STROJENIA: … albo skok |ω| powyżej, rad/s.
    public var releaseRotationRate: Double = 4.0
    /// DO STROJENIA: po strzale albo anulowaniu tyle sekund nic nie liczymy
    /// (odskok ręki po puszczeniu wyglądałby jak nowy naciąg), s.
    public var rearmDelay: TimeInterval = 0.6
    /// DO STROJENIA: najdłuższa kotwica, po której anulujemy (ręka opadła bez strzału), s.
    public var maxAnchorDuration: TimeInterval = 12
    /// DO STROJENIA: co ile próbek wysyłać stan na żywo (stabilność do kołysania celownika); 5 = 20 Hz.
    public var liveEverySamples: Int = 5

    public init() {}
}

/// Komplet ustawień WristKit.
public struct GestureTuning: Sendable, Hashable, Codable {
    public var flick = FlickTuning()
    public var overarm = OverarmTuning()
    public var draw = DrawTuning()

    public init() {}

    public static let `default` = GestureTuning()
}
