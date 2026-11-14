import Foundation

/// Around the Clock: trafiaj po kolei 1, 2, …, 20, a na koniec (opcjonalnie) środek.
///
/// - Liczy się każde pole z numerem celu (pojedyncze, podwójne, potrójne).
/// - **advanceByMultiplier** (opcja): podwójne przesuwa o 2, potrójne o 3 (szybszy wariant).
/// - Wygrywa pierwszy, kto trafi ostatni cel. Dobre na rozgrzewkę i do gry w pojedynkę.
public struct AroundTheClockRules: GameRules, Sendable, Hashable, Codable {
    public var finishOnBull: Bool
    public var advanceByMultiplier: Bool
    public var throwsPerTurn: Int

    public init(finishOnBull: Bool = true, advanceByMultiplier: Bool = false, throwsPerTurn: Int = 3) {
        self.finishOnBull = finishOnBull
        self.advanceByMultiplier = advanceByMultiplier
        self.throwsPerTurn = throwsPerTurn
    }

    public var descriptor: ModuleDescriptor { ModuleCatalog.darts }

    public var name: String {
        var parts = ["Around the Clock"]
        if advanceByMultiplier { parts.append("szybki") }
        if !finishOnBull { parts.append("bez środka") }
        return parts.joined(separator: " · ")
    }

    /// Cele w kolejności: 1…20 (+ 25 jako środek).
    public var sequence: [Int] { Array(1...20) + (finishOnBull ? [25] : []) }

    public func start(players: [PlayerID]) -> AroundTheClockState {
        AroundTheClockState(players: players, turn: TurnOrder(players: players, throwsPerTurn: throwsPerTurn))
    }

    public func apply(_ hit: DartHit, to state: AroundTheClockState) -> RulesStep<AroundTheClockState> {
        guard state.winner == nil else {
            return RulesStep(state: state, notices: [.message("Gra zakończona")])
        }
        var next = state
        let index = next.turn.currentIndex
        let player = next.turn.current
        next.dartsThisTurn.append(hit)
        next.dartsThrown[index] += 1

        var notices: [GameNotice] = []
        let sequence = sequence
        let position = next.progress[index]
        if position < sequence.count, hit.number == sequence[position] {
            // Na środku mnożnik nie przeskakuje dalej (to i tak ostatni cel).
            let step = advanceByMultiplier ? max(1, hit.multiplier) : 1
            next.progress[index] = min(sequence.count, position + step)
            next.hits[index] += 1
            notices.append(.scored(player: player, points: next.progress[index] - position))
        }

        if next.progress[index] >= sequence.count {
            next.winner = player
            next.dartsThisTurn = []
            return RulesStep(state: next, notices: notices + [.finished(winner: player)])
        }
        guard next.turn.recordThrow() else { return RulesStep(state: next, notices: notices) }
        next.dartsThisTurn = []
        return RulesStep(state: next, notices: notices + [.turnEnded(next: next.turn.current)])
    }

    public func winner(of state: AroundTheClockState) -> PlayerID? { state.winner }

    /// Bieżący cel gracza (nil = skończył).
    public func target(for player: Int, in state: AroundTheClockState) -> Int? {
        let position = state.progress[player]
        return position < sequence.count ? sequence[position] : nil
    }
}

/// Stan meczu Around the Clock.
public struct AroundTheClockState: Sendable, Hashable, Codable {
    public var players: [PlayerID]
    /// Ile celów gracz już zaliczył (indeks następnego celu w `sequence`).
    public var progress: [Int]
    public var turn: TurnOrder
    public var dartsThisTurn: [DartHit] = []
    public var dartsThrown: [Int]
    public var hits: [Int]
    public var winner: PlayerID?

    public init(players: [PlayerID], turn: TurnOrder) {
        self.players = players
        self.progress = Array(repeating: 0, count: players.count)
        self.turn = turn
        self.dartsThrown = Array(repeating: 0, count: players.count)
        self.hits = Array(repeating: 0, count: players.count)
    }

    /// Skuteczność: trafienia w cel / rzutki.
    public func accuracy(player: Int) -> Double? {
        guard dartsThrown[player] > 0 else { return nil }
        return Double(hits[player]) / Double(dartsThrown[player])
    }
}
