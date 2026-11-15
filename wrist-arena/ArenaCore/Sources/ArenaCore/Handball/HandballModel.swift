import Foundation
import WristKit

// ============================================================================
// DO STROJENIA
//
// Rzut karny w piłce ręcznej: zdarzenie rzutu → punkt w bramce, prędkość piłki
// i decyzja bramkarza AI. Wartości startowe to szacunki do strojenia w grze.
// ============================================================================

/// Bramka do piłki ręcznej (3 × 2 m), rzut karny z 7 m. Współrzędne w metrach:
/// x od środka bramki w prawo (z perspektywy rzucającego), y od podłogi w górę.
public struct HandballGoal: Sendable, Hashable, Codable {
    public var width = 3.0
    public var height = 2.0
    public var distance = 7.0
    /// Grubość słupka/poprzeczki: trafienie w ten pas to „słupek”, m.
    public var frame = 0.08

    public init() {}

    public static let standard = HandballGoal()

    public func contains(_ point: GoalPoint) -> Bool {
        abs(point.x) < width / 2 - frame / 2 && point.y > 0 && point.y < height - frame / 2
    }

    public func hitsFrame(_ point: GoalPoint) -> Bool {
        let side = abs(abs(point.x) - width / 2) <= frame / 2 && point.y >= 0 && point.y <= height + frame / 2
        let bar = abs(point.y - height) <= frame / 2 && abs(point.x) <= width / 2 + frame / 2
        return side || bar
    }

    /// Strefa 3 × 3 (do wyboru bramkarza i statystyk). Nil poza bramką.
    public func zone(of point: GoalPoint) -> GoalZone? {
        guard contains(point) else { return nil }
        let column = min(2, max(0, Int((point.x + width / 2) / (width / 3))))
        let row = min(2, max(0, Int(point.y / (height / 3))))
        return GoalZone(column: column, row: row)
    }

    public func center(of zone: GoalZone) -> GoalPoint {
        GoalPoint(
            x: -width / 2 + (Double(zone.column) + 0.5) * width / 3,
            y: (Double(zone.row) + 0.5) * height / 3
        )
    }
}

/// Punkt w płaszczyźnie bramki, m.
public struct GoalPoint: Sendable, Hashable, Codable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public func distance(to other: GoalPoint) -> Double {
        let dx = x - other.x, dy = y - other.y
        return (dx * dx + dy * dy).squareRoot()
    }
}

/// Strefa bramki: kolumna 0 = lewa, 2 = prawa (z perspektywy rzucającego); wiersz 0 = dół, 2 = góra.
public struct GoalZone: Sendable, Hashable, Codable, CaseIterable {
    public var column: Int
    public var row: Int

    public init(column: Int, row: Int) {
        self.column = column
        self.row = row
    }

    public static let allCases: [GoalZone] = (0..<3).flatMap { row in (0..<3).map { GoalZone(column: $0, row: row) } }

    public var name: String {
        let columns = ["lewy", "środek", "prawy"]
        let rows = ["dół", "środek", "góra"]
        if column == 1 && row == 1 { return "środek" }
        if column == 1 { return rows[row] }
        if row == 1 { return columns[column] }
        return "\(columns[column]) \(rows[row])"
    }
}

/// Poziom bramkarza AI.
public enum KeeperLevel: String, Sendable, Hashable, Codable, CaseIterable, CodingKeyRepresentable {
    case rookie, regular, pro
}

/// Parametry przeliczenia rzutu i bramkarza.
public struct HandballTuning: Sendable, Hashable, Codable {
    /// DO STROJENIA: wzmocnienie kąta (1 = fizycznie: 1° ≈ 12 cm z 7 m).
    public var aimGain: Double = 0.8
    /// DO STROJENIA: wysokość punktu celowania przy pitch = 0 (po kalibracji), m.
    public var aimHeight: Double = 1.0
    /// DO STROJENIA: `ThrowEvent.speed` (m/s) → km/h piłki.
    public var kmhPerSpeedUnit: Double = 9.5
    /// DO STROJENIA: poniżej tej prędkości piłka nie dolatuje / bramkarz łapie bez problemu, km/h.
    public var minBallSpeed: Double = 35
    /// DO STROJENIA: rozrzut (σ) na poziom trudności gracza, m.
    public var spread: [Difficulty: Double] = [.easy: 0.12, .normal: 0.2, .hard: 0.28, .pro: 0.36]
    /// DO STROJENIA: „wkrętka”: przesunięcie w bok na rad/s skrętu, m.
    public var curvePerSpin: Double = 0.03
    /// DO STROJENIA: czas reakcji bramkarza AI wg poziomu, s.
    public var reaction: [KeeperLevel: Double] = [.rookie: 0.32, .regular: 0.24, .pro: 0.17]
    /// DO STROJENIA: zasięg bramkarza bez ruchu (ręce/nogi), m.
    public var reach: Double = 0.55
    /// DO STROJENIA: szybkość „rzutu się” bramkarza, m/s.
    public var diveSpeed: Double = 5.5
    /// DO STROJENIA: szansa obrony piłki, którą bramkarz sięga.
    public var saveChance: Double = 0.85
    /// DO STROJENIA: szansa, że jeden zwód „kupi” bramkarza (rzuca się wcześniej w losowy róg).
    public var feintBite: [KeeperLevel: Double] = [.rookie: 0.5, .regular: 0.35, .pro: 0.2]
    /// DO STROJENIA: zasięg człowieka-bramkarza wokół wybranej strefy (tryb 2 graczy), m.
    public var humanKeeperReach: Double = 0.75

    public init() {}

    public static let `default` = HandballTuning()
}

/// Wynik strzału.
public enum ShotOutcome: String, Sendable, Hashable, Codable {
    case goal
    case saved
    case post
    case miss

    public var isGoal: Bool { self == .goal }
}

/// Strzał: gdzie poleciała piłka i jak szybko.
public struct HandballShot: Sendable, Hashable, Codable {
    public var aim: GoalPoint
    public var point: GoalPoint
    public var speedKmh: Double
    public var spread: Double

    public init(aim: GoalPoint, point: GoalPoint, speedKmh: Double, spread: Double) {
        self.aim = aim
        self.point = point
        self.speedKmh = speedKmh
        self.spread = spread
    }
}

/// Jak zachował się bramkarz.
public struct KeeperAction: Sendable, Hashable, Codable {
    /// Gdzie bramkarz się rzucił / stał (środek ruchu).
    public var position: GoalPoint
    /// Rzucił się wcześniej po zwodzie.
    public var fooledByFeint: Bool

    public init(position: GoalPoint, fooledByFeint: Bool) {
        self.position = position
        self.fooledByFeint = fooledByFeint
    }
}

/// Zdarzenie rzutu → strzał, oraz decyzja bramkarza.
public struct HandballModel: Sendable, Hashable, Codable {
    public var tuning: HandballTuning
    public var goal: HandballGoal

    public init(tuning: HandballTuning = .default, goal: HandballGoal = .standard) {
        self.tuning = tuning
        self.goal = goal
    }

    public func aimPoint(for event: ThrowEvent, calibration: Calibration) -> GoalPoint {
        let (yaw, pitch) = calibration.apply(yaw: event.yaw, pitch: event.pitch)
        let scale = goal.distance * tuning.aimGain
        return GoalPoint(
            x: scale * tan(yaw) + tuning.curvePerSpin * event.spin,
            y: tuning.aimHeight + scale * tan(pitch)
        )
    }

    public func shot<G: RandomNumberGenerator>(
        _ event: ThrowEvent,
        calibration: Calibration,
        difficulty: Difficulty,
        using rng: inout G
    ) -> HandballShot {
        let aim = aimPoint(for: event, calibration: calibration)
        return shot(aim: aim, speedKmh: event.speed * tuning.kmhPerSpeedUnit, difficulty: difficulty, using: &rng)
    }

    /// Strzał z celowania dotykiem (tryb bez zegarka): stała, średnia prędkość.
    public func shot<G: RandomNumberGenerator>(
        aim: GoalPoint,
        speedKmh: Double = 85,
        difficulty: Difficulty,
        using rng: inout G
    ) -> HandballShot {
        let spread = tuning.spread[difficulty] ?? 0.2
        let point = GoalPoint(x: aim.x + rng.nextGaussian() * spread, y: aim.y + rng.nextGaussian() * spread)
        return HandballShot(aim: aim, point: point, speedKmh: speedKmh, spread: spread)
    }

    /// Bramkarz AI: reaguje, jeśli zdąży (czas lotu − czas reakcji), chyba że zwód kazał mu rzucić się wcześniej.
    public func keeperAI<G: RandomNumberGenerator>(
        level: KeeperLevel,
        feints: Int,
        shot: HandballShot,
        using rng: inout G
    ) -> (KeeperAction, ShotOutcome) {
        let home = GoalPoint(x: 0, y: goal.height * 0.45)
        let bite = 1 - pow(1 - (tuning.feintBite[level] ?? 0.35), Double(feints))
        if feints > 0, Double.random(in: 0..<1, using: &rng) < bite {
            let zone = GoalZone(column: Bool.random(using: &rng) ? 0 : 2, row: Int.random(in: 0...2, using: &rng))
            let position = goal.center(of: zone)
            return (KeeperAction(position: position, fooledByFeint: true),
                    resolve(shot, keeper: position, reach: tuning.reach, using: &rng))
        }
        let flight = goal.distance / max(shot.speedKmh / 3.6, 1)
        let reaction = tuning.reaction[level] ?? 0.24
        let travel = max(0, flight - reaction) * tuning.diveSpeed
        let target = shot.point
        let distance = home.distance(to: target)
        let moved = min(travel, distance)
        let position = distance > 0
            ? GoalPoint(x: home.x + (target.x - home.x) * moved / distance, y: home.y + (target.y - home.y) * moved / distance)
            : home
        return (KeeperAction(position: position, fooledByFeint: false),
                resolve(shot, keeper: position, reach: tuning.reach, using: &rng))
    }

    /// Bramkarz-człowiek wybrał strefę przed rzutem (tryb 2 graczy).
    public func humanKeeper<G: RandomNumberGenerator>(
        zone: GoalZone,
        shot: HandballShot,
        using rng: inout G
    ) -> (KeeperAction, ShotOutcome) {
        let position = goal.center(of: zone)
        return (KeeperAction(position: position, fooledByFeint: false),
                resolve(shot, keeper: position, reach: tuning.humanKeeperReach, using: &rng))
    }

    private func resolve<G: RandomNumberGenerator>(
        _ shot: HandballShot,
        keeper: GoalPoint,
        reach: Double,
        using rng: inout G
    ) -> ShotOutcome {
        if goal.hitsFrame(shot.point) { return .post }
        guard goal.contains(shot.point) else { return .miss }
        if shot.speedKmh < tuning.minBallSpeed { return .saved }
        if keeper.distance(to: shot.point) <= reach, Double.random(in: 0..<1, using: &rng) < tuning.saveChance {
            return .saved
        }
        return .goal
    }
}
