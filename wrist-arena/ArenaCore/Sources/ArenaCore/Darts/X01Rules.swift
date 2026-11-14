import Foundation
import WristKit

/// Reguły gier X01 (301, 501, 701): odliczanie od zadanej liczby do zera.
///
/// - **double-out** (domyślnie włączone): ostatnia rzutka musi trafić w podwójne pole
///   albo w środek 50. Zostawienie 1 albo zejście poniżej 0 to „bust”.
/// - **double-in** (opcjonalnie): punkty liczą się dopiero od pierwszego podwójnego.
/// - **bust**: wynik wraca do stanu z początku tury, tura się kończy.
public struct X01Rules: GameRules, Sendable, Hashable, Codable {
    public var startScore: Int
    public var doubleOut: Bool
    public var doubleIn: Bool
    public var throwsPerTurn: Int

    public init(startScore: Int = 501, doubleOut: Bool = true, doubleIn: Bool = false, throwsPerTurn: Int = 3) {
        self.startScore = startScore
        self.doubleOut = doubleOut
        self.doubleIn = doubleIn
        self.throwsPerTurn = throwsPerTurn
    }

    public var descriptor: ModuleDescriptor { ModuleCatalog.darts }

    public var name: String {
        var parts = ["\(startScore)"]
        if doubleIn { parts.append("double-in") }
        if doubleOut { parts.append("double-out") }
        return parts.joined(separator: " · ")
    }

    public func start(players: [PlayerID]) -> X01State {
        X01State(
            players: players,
            remaining: Array(repeating: startScore, count: players.count),
            opened: Array(repeating: !doubleIn, count: players.count),
            turn: TurnOrder(players: players, throwsPerTurn: throwsPerTurn)
        )
    }

    public func apply(_ hit: DartHit, to state: X01State) -> RulesStep<X01State> {
        guard state.winner == nil else {
            return RulesStep(state: state, notices: [.message("Gra zakończona")])
        }
        var next = state
        let index = next.turn.currentIndex
        let player = next.turn.current
        if next.dartsThisTurn.isEmpty {
            next.turnStartScore = next.remaining[index]
            next.turnStartOpened = next.opened[index]
        }
        next.dartsThisTurn.append(hit)
        next.dartsThrown[index] += 1

        if !next.opened[index] {
            if hit.isDouble {
                next.opened[index] = true
            } else {
                return finishDart(next, notices: [.scored(player: player, points: 0)])
            }
        }

        let after = next.remaining[index] - hit.score
        let finishedOnDouble = hit.isDouble || !doubleOut
        let isBust = after < 0 || (doubleOut && after == 1) || (after == 0 && !finishedOnDouble)
        if isBust {
            next.remaining[index] = next.turnStartScore
            next.opened[index] = next.turnStartOpened
            next.pointsScored[index] -= next.turnPoints
            next.history.append(X01Turn(player: player, darts: next.dartsThisTurn, scoreBefore: next.turnStartScore, bust: true))
            next.dartsThisTurn = []
            next.turnPoints = 0
            next.turn.endTurn()
            return RulesStep(state: next, notices: [.bust(player: player), .turnEnded(next: next.turn.current)])
        }

        next.remaining[index] = after
        next.pointsScored[index] += hit.score
        next.turnPoints += hit.score
        if after == 0 {
            next.winner = player
            next.history.append(X01Turn(player: player, darts: next.dartsThisTurn, scoreBefore: next.turnStartScore, bust: false))
            next.dartsThisTurn = []
            next.turnPoints = 0
            return RulesStep(state: next, notices: [.scored(player: player, points: hit.score), .finished(winner: player)])
        }
        return finishDart(next, notices: [.scored(player: player, points: hit.score)])
    }

    /// Zalicza rzutkę w turze; po ostatniej zamyka turę.
    private func finishDart(_ state: X01State, notices: [GameNotice]) -> RulesStep<X01State> {
        var next = state
        let player = next.turn.current
        guard next.turn.recordThrow() else { return RulesStep(state: next, notices: notices) }
        next.history.append(X01Turn(player: player, darts: next.dartsThisTurn, scoreBefore: next.turnStartScore, bust: false))
        next.dartsThisTurn = []
        next.turnPoints = 0
        return RulesStep(state: next, notices: notices + [.turnEnded(next: next.turn.current)])
    }

    public func winner(of state: X01State) -> PlayerID? { state.winner }

    /// Podpowiedź zamknięcia: najkrótsza sekwencja rzutek kończąca grę (nil = nie da się
    /// w `dartsLeft` rzutkach). Preferuje trójki przed pojedynczymi i „ładne” podwójne (D20, D16).
    public func checkout(for remaining: Int, dartsLeft: Int = 3) -> [DartHit]? {
        Self.checkout(remaining: remaining, dartsLeft: dartsLeft, doubleOut: doubleOut)
    }

    static func checkout(remaining: Int, dartsLeft: Int, doubleOut: Bool) -> [DartHit]? {
        guard remaining > 0, dartsLeft > 0 else { return nil }
        for count in 1...dartsLeft {
            if let path = search(remaining: remaining, darts: count, doubleOut: doubleOut) {
                return path
            }
        }
        return nil
    }

    /// Kolejność prób: preferowane pola najpierw, więc pierwsze znalezione rozwiązanie jest „typowe”.
    private static let setupHits: [DartHit] = {
        let triples = (1...20).reversed().map(DartHit.triple)
        let singles = (1...20).reversed().map(DartHit.single)
        let doubles = (1...20).reversed().map(DartHit.double)
        return triples + [.outerBull] + singles + doubles + [.innerBull]
    }()

    private static let finishingDoubles: [DartHit] = {
        let preferred = [20, 16, 8, 12, 10, 18, 4, 6, 2, 14, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19]
        return preferred.map(DartHit.double) + [.innerBull]
    }()

    private static func search(remaining: Int, darts: Int, doubleOut: Bool) -> [DartHit]? {
        if darts == 1 {
            let finishers = doubleOut ? finishingDoubles : setupHits + finishingDoubles
            return finishers.first { $0.score == remaining }.map { [$0] }
        }
        for hit in setupHits where hit.score < remaining {
            if let rest = search(remaining: remaining - hit.score, darts: darts - 1, doubleOut: doubleOut) {
                return [hit] + rest
            }
        }
        return nil
    }
}

/// Jedna zakończona tura (do historii i statystyk).
public struct X01Turn: Sendable, Hashable, Codable {
    public var player: PlayerID
    public var darts: [DartHit]
    public var scoreBefore: Int
    public var bust: Bool

    public init(player: PlayerID, darts: [DartHit], scoreBefore: Int, bust: Bool) {
        self.player = player
        self.darts = darts
        self.scoreBefore = scoreBefore
        self.bust = bust
    }

    public var points: Int { bust ? 0 : darts.reduce(0) { $0 + $1.score } }
}

/// Stan meczu X01. Tablice indeksowane kolejnością graczy w `players`.
public struct X01State: Sendable, Hashable, Codable {
    public var players: [PlayerID]
    public var remaining: [Int]
    /// Czy gracz już „otworzył” (double-in). Bez double-in zawsze `true`.
    public var opened: [Bool]
    public var turn: TurnOrder
    public var dartsThisTurn: [DartHit] = []
    public var turnStartScore = 0
    public var turnStartOpened = true
    /// Punkty zdobyte w bieżącej turze (do cofnięcia przy bust).
    public var turnPoints = 0
    public var dartsThrown: [Int]
    public var pointsScored: [Int]
    public var history: [X01Turn] = []
    public var winner: PlayerID?

    public init(players: [PlayerID], remaining: [Int], opened: [Bool], turn: TurnOrder) {
        self.players = players
        self.remaining = remaining
        self.opened = opened
        self.turn = turn
        self.dartsThrown = Array(repeating: 0, count: players.count)
        self.pointsScored = Array(repeating: 0, count: players.count)
    }

    public var currentPlayer: PlayerID { turn.current }

    public func index(of player: PlayerID) -> Int? { players.firstIndex(of: player) }

    public func remaining(for player: PlayerID) -> Int? { index(of: player).map { remaining[$0] } }

    /// Średnia na 3 rzutki (standard w darcie): punkty / rzutki × 3. Busty liczą się jako 0.
    public func threeDartAverage(for player: PlayerID) -> Double? {
        guard let i = index(of: player), dartsThrown[i] > 0 else { return nil }
        return Double(pointsScored[i]) / Double(dartsThrown[i]) * 3
    }

    public var dartsLeftInTurn: Int { turn.throwsPerTurn - dartsThisTurn.count }
}
