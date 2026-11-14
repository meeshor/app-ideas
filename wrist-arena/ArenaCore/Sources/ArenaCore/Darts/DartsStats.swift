import Foundation

/// Statystyki jednego gracza w jednym meczu (liczone z dziennika i stanu po meczu).
public struct PlayerMatchStats: Sendable, Hashable, Codable {
    public var player: PlayerID
    public var won = false
    public var darts = 0
    public var triples = 0
    public var doubles = 0
    /// Trafienia w środek (25 i 50).
    public var bulls = 0
    public var misses = 0
    // X01
    public var x01Points = 0
    public var x01Darts = 0
    public var bestTurn = 0
    public var busts = 0
    /// Wynik tury, którą gracz zamknął grę (np. 121), jeśli wygrał X01.
    public var checkout: Int?
    // Cricket
    public var cricketMarks = 0
    public var cricketDarts = 0
    public var bestCricketTurnMarks = 0
    // Around the Clock
    public var clockHits = 0
    public var clockDarts = 0
    /// Liczba rzutek do ukończenia (tylko gdy gracz ukończył).
    public var clockFinishDarts: Int?

    public init(player: PlayerID) {
        self.player = player
    }

    /// Średnia X01 na 3 rzutki.
    public var x01Average: Double? {
        x01Darts > 0 ? Double(x01Points) / Double(x01Darts) * 3 : nil
    }

    /// Znaki na rundę w Cricket.
    public var marksPerRound: Double? {
        cricketDarts > 0 ? Double(cricketMarks) / Double(cricketDarts) * 3 : nil
    }
}

extension DartsMatch {
    /// Statystyki wszystkich graczy (w kolejności `players`).
    public var stats: [PlayerMatchStats] {
        players.indices.map { index in
            let id = players[index].id
            var stats = PlayerMatchStats(player: id)
            stats.won = state.winner == id
            for record in log where record.player == id {
                stats.darts += 1
                switch record.hit.ring {
                case .triple: stats.triples += 1
                case .double: stats.doubles += 1
                case .innerBull, .outerBull: stats.bulls += 1
                case .miss: stats.misses += 1
                case .single: break
                }
            }
            switch state {
            case .x01(let s):
                stats.x01Points = s.pointsScored[index]
                stats.x01Darts = s.dartsThrown[index]
                let turns = s.history.filter { $0.player == id }
                stats.bestTurn = turns.map(\.points).max() ?? 0
                stats.busts = turns.filter(\.bust).count
                if stats.won, let last = turns.last { stats.checkout = last.points }
            case .cricket(let s):
                stats.cricketMarks = s.marksScored[index]
                stats.cricketDarts = s.dartsThrown[index]
                stats.bestCricketTurnMarks = max(s.turnMarksHistory[index].max() ?? 0, s.turnMarks)
            case .aroundTheClock(let s):
                stats.clockHits = s.hits[index]
                stats.clockDarts = s.dartsThrown[index]
                if stats.won { stats.clockFinishDarts = s.dartsThrown[index] }
            }
            return stats
        }
    }
}

/// Statystyki gracza narastająco ze wszystkich meczów (zapisywane w profilu aplikacji).
public struct PlayerStats: Sendable, Hashable, Codable {
    public var matches = 0
    public var wins = 0
    public var darts = 0
    public var triples = 0
    public var doubles = 0
    public var bulls = 0
    public var misses = 0
    public var x01Matches = 0
    public var x01Points = 0
    public var x01Darts = 0
    public var bestTurn = 0
    public var highestCheckout = 0
    public var busts = 0
    public var cricketMatches = 0
    public var cricketMarks = 0
    public var cricketDarts = 0
    public var clockMatches = 0
    public var clockHits = 0
    public var clockDarts = 0
    public var bestClockFinish: Int?

    public init() {}

    public mutating func add(_ match: PlayerMatchStats, game: DartsGame) {
        matches += 1
        if match.won { wins += 1 }
        darts += match.darts
        triples += match.triples
        doubles += match.doubles
        bulls += match.bulls
        misses += match.misses
        switch game {
        case .x01:
            x01Matches += 1
            x01Points += match.x01Points
            x01Darts += match.x01Darts
            bestTurn = max(bestTurn, match.bestTurn)
            highestCheckout = max(highestCheckout, match.checkout ?? 0)
            busts += match.busts
        case .cricket:
            cricketMatches += 1
            cricketMarks += match.cricketMarks
            cricketDarts += match.cricketDarts
        case .aroundTheClock:
            clockMatches += 1
            clockHits += match.clockHits
            clockDarts += match.clockDarts
            if let finish = match.clockFinishDarts {
                bestClockFinish = min(bestClockFinish ?? .max, finish)
            }
        }
    }

    public var winRate: Double? { matches > 0 ? Double(wins) / Double(matches) : nil }
    public var x01Average: Double? { x01Darts > 0 ? Double(x01Points) / Double(x01Darts) * 3 : nil }
    public var marksPerRound: Double? { cricketDarts > 0 ? Double(cricketMarks) / Double(cricketDarts) * 3 : nil }
    public var clockAccuracy: Double? { clockDarts > 0 ? Double(clockHits) / Double(clockDarts) : nil }
    public var missRate: Double? { darts > 0 ? Double(misses) / Double(darts) : nil }
}
