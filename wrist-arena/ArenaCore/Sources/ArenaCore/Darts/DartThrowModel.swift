import Foundation
import WristKit

// ============================================================================
// DO STROJENIA
//
// Jak zdarzenie rzutu z zegarka zamienia się w punkt na tarczy. Wartości startowe
// to szacunki; stroimy je po pierwszych grach na prawdziwym zegarku.
// ============================================================================

/// Parametry przeliczenia rzutu na tarczę.
public struct DartsTuning: Sendable, Hashable, Codable {
    /// Odległość od tarczy (oficjalnie 2,37 m), m.
    public var throwDistance: Double = 2.37
    /// DO STROJENIA: wzmocnienie kąta. 1 = fizycznie (1° ≈ 41 mm na tarczy), mniej = łatwiej.
    public var aimGain: Double = 0.6
    /// DO STROJENIA: „idealna” prędkość z `ThrowEvent.speed`, przy której rzutka nie opada, m/s.
    /// Domyślnie z syntetycznego rzutu (12 rad/s × 0,35 m); po kalibracji: średnia gracza.
    public var referenceSpeed: Double = 4.2
    /// DO STROJENIA: ile mm opada rzutka przy prędkości 0,8 × referencyjnej (rośnie z 1/v²).
    public var dropAtEightyPercent: Double = 40
    /// DO STROJENIA: poniżej tego ułamka prędkości referencyjnej rzutka nie dolatuje (pudło).
    public var minSpeedRatio: Double = 0.4
    /// DO STROJENIA: odchylenie standardowe rozrzutu na każdym poziomie trudności, mm.
    public var spread: [Difficulty: Double] = [.easy: 8, .normal: 14, .hard: 20, .pro: 26]
    /// DO STROJENIA: jerk poniżej tej wartości nie zwiększa rozrzutu.
    public var smoothJerk: Double = 1.0
    /// DO STROJENIA: przyrost rozrzutu na każdą jednostkę jerku ponad `smoothJerk` (×).
    public var jerkSpreadGain: Double = 0.6
    /// DO STROJENIA: |spin| (rad/s) poniżej tej wartości nie zwiększa rozrzutu.
    public var freeSpin: Double = 2
    /// DO STROJENIA: przyrost rozrzutu na każdy rad/s spinu ponad `freeSpin` (×).
    public var spinSpreadGain: Double = 0.1
    /// DO STROJENIA: spin skręca tor w bok, mm na rad/s (znak: supinacja → w prawo).
    public var spinCurve: Double = 3

    public init() {}

    public static let `default` = DartsTuning()

    /// Bazowy rozrzut dla poziomu trudności, mm.
    public func baseSpread(for difficulty: Difficulty) -> Double {
        spread[difficulty] ?? 14
    }
}

/// Gdzie wbiła się rzutka.
public struct DartLanding: Sendable, Hashable, Codable {
    /// Punkt celowania (z kierunku rzutu, przed rozrzutem).
    public var aim: BoardPoint
    /// Punkt trafienia.
    public var point: BoardPoint
    public var hit: DartHit
    /// Odchylenie standardowe użytego rozrzutu, mm (do podglądu „pewności” rzutu).
    public var spread: Double

    public init(aim: BoardPoint, point: BoardPoint, hit: DartHit, spread: Double) {
        self.aim = aim
        self.point = point
        self.hit = hit
        self.spread = spread
    }
}

/// Zamienia `ThrowEvent` na trafienie: kierunek → punkt celowania, prędkość → opadanie,
/// jerk i spin → większy rozrzut. Losowość tylko z przekazanego generatora (powtarzalne testy).
public struct DartThrowModel: Sendable, Hashable, Codable {
    public var tuning: DartsTuning
    public var board: Dartboard

    public init(tuning: DartsTuning = .default, board: Dartboard = .standard) {
        self.tuning = tuning
        self.board = board
    }

    /// Punkt celowania bez losowości (po kalibracji gracza).
    public func aimPoint(for event: ThrowEvent, calibration: Calibration) -> BoardPoint? {
        let speedRatio = event.speed / tuning.referenceSpeed
        guard speedRatio >= tuning.minSpeedRatio else { return nil }
        let (yaw, pitch) = calibration.apply(yaw: event.yaw, pitch: event.pitch)
        let scale = tuning.throwDistance * 1000 * tuning.aimGain
        // Opadanie ∝ 1/v² − 1, znormalizowane tak, żeby przy 0,8 × v_ref wynosiło dropAtEightyPercent.
        let dropUnit = 1 / (0.8 * 0.8) - 1
        let drop = tuning.dropAtEightyPercent * (1 / (speedRatio * speedRatio) - 1) / dropUnit
        let curve = tuning.spinCurve * event.spin
        return BoardPoint(x: scale * tan(yaw) + curve, y: scale * tan(pitch) - drop)
    }

    /// Odchylenie standardowe rozrzutu dla rzutu, mm.
    public func spread(for event: ThrowEvent, difficulty: Difficulty) -> Double {
        let jerkExcess = max(0, event.jerk - tuning.smoothJerk)
        let spinExcess = max(0, abs(event.spin) - tuning.freeSpin)
        return tuning.baseSpread(for: difficulty)
            * (1 + tuning.jerkSpreadGain * jerkExcess)
            * (1 + tuning.spinSpreadGain * spinExcess)
    }

    /// Pełny rzut: celowanie + rozrzut. Zbyt słaby rzut = pudło poniżej tarczy.
    public func land<G: RandomNumberGenerator>(
        _ event: ThrowEvent,
        calibration: Calibration,
        difficulty: Difficulty,
        using rng: inout G
    ) -> DartLanding {
        let spread = spread(for: event, difficulty: difficulty)
        guard let aim = aimPoint(for: event, calibration: calibration) else {
            let floor = BoardPoint(x: 0, y: -(board.doubleOuterRadius + 60))
            return DartLanding(aim: floor, point: floor, hit: .miss, spread: spread)
        }
        let point = BoardPoint(
            x: aim.x + rng.nextGaussian() * spread,
            y: aim.y + rng.nextGaussian() * spread
        )
        return DartLanding(aim: aim, point: point, hit: board.hit(at: point), spread: spread)
    }

    /// Trafienie z dotyku/kliknięcia w punkt tarczy (tryb dotykowy i testy): ten sam rozrzut.
    public func land<G: RandomNumberGenerator>(
        aimingAt aim: BoardPoint,
        difficulty: Difficulty,
        using rng: inout G
    ) -> DartLanding {
        let spread = tuning.baseSpread(for: difficulty)
        let point = BoardPoint(
            x: aim.x + rng.nextGaussian() * spread,
            y: aim.y + rng.nextGaussian() * spread
        )
        return DartLanding(aim: aim, point: point, hit: board.hit(at: point), spread: spread)
    }
}
