import Foundation
import WristKit

/// Seria strzał na jednym dystansie (MVP: serie po 3, kilka serii w rundzie).
public struct ArcheryRound: Sendable, Hashable, Codable {
    public var conditions: ShotConditions
    public var arrowsPerEnd: Int
    public var ends: Int
    public private(set) var arrows: [ArrowResult] = []

    public init(conditions: ShotConditions, arrowsPerEnd: Int = 3, ends: Int = 2) {
        self.conditions = conditions
        self.arrowsPerEnd = arrowsPerEnd
        self.ends = ends
    }

    public var totalArrows: Int { arrowsPerEnd * ends }
    public var isComplete: Bool { arrows.count >= totalArrows }
    public var total: Int { arrows.reduce(0) { $0 + $1.score.value } }
    public var xCount: Int { arrows.filter(\.score.isX).count }
    public var maxScore: Int { totalArrows * 10 }

    /// Bieżąca seria (1…ends).
    public var currentEnd: Int { min(ends, arrows.count / arrowsPerEnd + 1) }

    /// Strzały w seriach (do tabeli wyników).
    public var endScores: [[ArrowScore]] {
        stride(from: 0, to: arrows.count, by: arrowsPerEnd).map { start in
            arrows[start..<min(start + arrowsPerEnd, arrows.count)].map(\.score)
        }
    }

    @discardableResult
    public mutating func add(_ arrow: ArrowResult) -> Bool {
        guard !isComplete else { return false }
        arrows.append(arrow)
        return true
    }

    public mutating func undo() {
        _ = arrows.popLast()
    }
}

/// Rekordy osobiste per dystans i liczba strzał (np. „18 m · 6 strzał”).
public struct PersonalBests: Sendable, Hashable, Codable {
    public struct Key: Sendable, Hashable, Codable, CustomStringConvertible {
        public var distance: Int
        public var arrows: Int
        public var description: String { "\(distance) m · \(arrows) strzał" }
    }

    public struct Record: Sendable, Hashable, Codable {
        public var total: Int
        public var xCount: Int
    }

    public private(set) var records: [Key: Record] = [:]

    public init() {}

    /// Zapisuje wynik rundy; zwraca `true`, gdy to nowy rekord (wyżej punkty, przy remisie więcej X).
    @discardableResult
    public mutating func submit(_ round: ArcheryRound) -> Bool {
        guard round.isComplete else { return false }
        let key = Key(distance: Int(round.conditions.distance.rounded()), arrows: round.totalArrows)
        let candidate = Record(total: round.total, xCount: round.xCount)
        if let best = records[key], (best.total, best.xCount) >= (candidate.total, candidate.xCount) {
            return false
        }
        records[key] = candidate
        return true
    }

    public func best(distance: Double, arrows: Int) -> Record? {
        records[Key(distance: Int(distance.rounded()), arrows: arrows)]
    }
}

/// Wyzwanie dnia: stały seed z daty → te same warunki (dystans, wiatr, ziarno kołysania) dla wszystkich.
public struct DailyChallenge: Sendable, Hashable, Codable {
    public var year: Int
    public var month: Int
    public var day: Int
    public var distance: Double
    public var wind: Wind
    public var swaySeed: UInt64
    public var arrows: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
        var rng = SeededRandom(seed: Self.seed(year: year, month: month, day: day))
        distance = [18.0, 30.0, 30.0, 50.0].randomElement(using: &rng) ?? 18
        // Wiatr: zwykle słaby, czasem porywisty (rozkład zbliżony do warunków na otwartym torze).
        let strength = pow(Double.random(in: 0..<1, using: &rng), 1.5) * 6
        let direction = Double.random(in: -Double.pi ... Double.pi, using: &rng)
        wind = distance < 25 ? .calm : Wind(cross: strength * sin(direction), head: strength * cos(direction))
        swaySeed = rng.next()
        arrows = 6
    }

    /// Ziarno niezależne od strefy czasowej i od kalendarza systemu (proste mieszanie liczb).
    public static func seed(year: Int, month: Int, day: Int) -> UInt64 {
        var rng = SeededRandom(seed: UInt64(year * 10_000 + month * 100 + day))
        return rng.next()
    }

    public var id: String { String(format: "%04d-%02d-%02d", year, month, day) }

    public var conditions: ShotConditions { ShotConditions(distance: distance, wind: wind) }

    /// Ziarno kołysania dla n-tej strzały (każda strzała inny „taniec” celownika, ale ten sam dla wszystkich graczy).
    public func swaySeed(arrow index: Int) -> UInt64 {
        var rng = SeededRandom(seed: swaySeed &+ UInt64(index))
        return rng.next()
    }
}
