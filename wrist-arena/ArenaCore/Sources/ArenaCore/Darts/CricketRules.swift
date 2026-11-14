import Foundation

/// Cricket: zamykanie pól 15–20 i środka.
///
/// - Trafienia dają „znaki”: pojedyncze 1, podwójne 2, potrójne 3; środek 25 = 1, 50 = 2.
/// - 3 znaki zamykają pole. Kolejne znaki na zamkniętym polu dają punkty (wartość pola × nadmiar),
///   o ile choć jeden przeciwnik go nie zamknął.
/// - **cut-throat** (opcja): punkty dostają przeciwnicy, którzy pola nie zamknęli; wygrywa najmniej punktów.
/// - Wygrywa gracz, który zamknął wszystko i ma nie gorszy wynik od każdego przeciwnika.
/// - Limit rund (domyślnie 20): po nim wygrywa najlepszy wynik, przy remisie więcej znaków, potem kolejność.
public struct CricketRules: GameRules, Sendable, Hashable, Codable {
    /// Pola w grze, w kolejności wyświetlania (25 = środek).
    public static let targets = [20, 19, 18, 17, 16, 15, 25]
    public static let marksToClose = 3

    public var cutThroat: Bool
    public var roundLimit: Int?
    public var throwsPerTurn: Int

    public init(cutThroat: Bool = false, roundLimit: Int? = 20, throwsPerTurn: Int = 3) {
        self.cutThroat = cutThroat
        self.roundLimit = roundLimit
        self.throwsPerTurn = throwsPerTurn
    }

    public var descriptor: ModuleDescriptor { ModuleCatalog.darts }

    public var name: String { cutThroat ? "Cricket · cut-throat" : "Cricket" }

    /// Ile znaków daje trafienie (0 dla pól spoza gry).
    public static func marks(for hit: DartHit) -> Int {
        guard targets.contains(hit.number) else { return 0 }
        return hit.multiplier
    }

    public func start(players: [PlayerID]) -> CricketState {
        CricketState(players: players, turn: TurnOrder(players: players, throwsPerTurn: throwsPerTurn))
    }

    public func apply(_ hit: DartHit, to state: CricketState) -> RulesStep<CricketState> {
        guard state.winner == nil else {
            return RulesStep(state: state, notices: [.message("Gra zakończona")])
        }
        var next = state
        let index = next.turn.currentIndex
        let player = next.turn.current
        next.dartsThisTurn.append(hit)
        next.dartsThrown[index] += 1

        var notices: [GameNotice] = []
        let marks = Self.marks(for: hit)
        if marks > 0, let target = Self.targets.firstIndex(of: hit.number) {
            let before = next.marks[index][target]
            let closing = min(marks, max(0, Self.marksToClose - before))
            let extra = marks - closing
            next.marks[index][target] = before + marks
            next.marksScored[index] += marks
            next.turnMarks += marks
            if extra > 0 {
                let points = extra * hit.number
                let open = next.players.indices.filter { $0 != index && !next.isClosed(player: $0, target: target) }
                if !open.isEmpty {
                    if cutThroat {
                        for other in open { next.points[other] += points }
                    } else {
                        next.points[index] += points
                    }
                    notices.append(.scored(player: player, points: points))
                }
            }
        }

        if let winner = immediateWinner(in: next) {
            next.winner = next.players[winner]
            next.closeTurn(player: index)
            return RulesStep(state: next, notices: notices + [.finished(winner: next.players[winner])])
        }

        guard next.turn.recordThrow() else { return RulesStep(state: next, notices: notices) }
        next.closeTurn(player: index)
        if let roundLimit, next.turn.currentIndex == 0, next.turn.round > roundLimit {
            let winner = limitWinner(in: next)
            next.winner = next.players[winner]
            return RulesStep(state: next, notices: notices + [.finished(winner: next.players[winner])])
        }
        return RulesStep(state: next, notices: notices + [.turnEnded(next: next.turn.current)])
    }

    public func winner(of state: CricketState) -> PlayerID? { state.winner }

    /// Bieżący gracz zamknął wszystko i ma nie gorszy wynik od każdego przeciwnika.
    private func immediateWinner(in state: CricketState) -> Int? {
        let index = state.turn.currentIndex
        guard state.closedAll(player: index) else { return nil }
        let mine = state.points[index]
        let others = state.players.indices.filter { $0 != index }.map { state.points[$0] }
        let ok = cutThroat ? others.allSatisfy { mine <= $0 } : others.allSatisfy { mine >= $0 }
        return ok ? index : nil
    }

    private func limitWinner(in state: CricketState) -> Int {
        state.players.indices.min { a, b in
            let pa = state.points[a], pb = state.points[b]
            if pa != pb { return cutThroat ? pa < pb : pa > pb }
            let ca = state.closedCount(player: a), cb = state.closedCount(player: b)
            if ca != cb { return ca > cb }
            return a < b
        } ?? 0
    }
}

/// Stan meczu Cricket. Tablice indeksowane kolejnością graczy.
public struct CricketState: Sendable, Hashable, Codable {
    public var players: [PlayerID]
    /// Znaki [gracz][pole z `CricketRules.targets`] (mogą przekraczać 3).
    public var marks: [[Int]]
    public var points: [Int]
    public var turn: TurnOrder
    public var dartsThisTurn: [DartHit] = []
    public var turnMarks = 0
    public var dartsThrown: [Int]
    public var marksScored: [Int]
    /// Znaki w każdej zakończonej turze (do statystyk MPR i najlepszej tury).
    public var turnMarksHistory: [[Int]]
    public var winner: PlayerID?

    public init(players: [PlayerID], turn: TurnOrder) {
        let count = players.count
        self.players = players
        self.marks = Array(repeating: Array(repeating: 0, count: CricketRules.targets.count), count: count)
        self.points = Array(repeating: 0, count: count)
        self.turn = turn
        self.dartsThrown = Array(repeating: 0, count: count)
        self.marksScored = Array(repeating: 0, count: count)
        self.turnMarksHistory = Array(repeating: [], count: count)
    }

    public func isClosed(player: Int, target: Int) -> Bool {
        marks[player][target] >= CricketRules.marksToClose
    }

    public func closedAll(player: Int) -> Bool {
        CricketRules.targets.indices.allSatisfy { isClosed(player: player, target: $0) }
    }

    public func closedCount(player: Int) -> Int {
        CricketRules.targets.indices.filter { isClosed(player: player, target: $0) }.count
    }

    /// Znaki na polu, przycięte do 3 (do rysowania /, X, ⊗).
    public func displayMarks(player: Int, target: Int) -> Int {
        min(marks[player][target], CricketRules.marksToClose)
    }

    /// Znaki na rundę (MPR): standardowa miara w Cricket.
    public func marksPerRound(player: Int) -> Double? {
        guard dartsThrown[player] > 0 else { return nil }
        return Double(marksScored[player]) / Double(dartsThrown[player]) * 3
    }

    mutating func closeTurn(player index: Int) {
        if !dartsThisTurn.isEmpty {
            turnMarksHistory[index].append(turnMarks)
        }
        dartsThisTurn = []
        turnMarks = 0
    }
}
