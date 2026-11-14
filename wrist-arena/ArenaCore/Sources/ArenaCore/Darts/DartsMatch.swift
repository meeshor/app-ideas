import Foundation
import WristKit

/// Jedna rzutka w dzienniku meczu (statystyki, mapa trafień).
public struct DartRecord: Sendable, Hashable, Codable {
    public var player: PlayerID
    public var hit: DartHit
    /// Miejsce trafienia (nil, gdy trafienie wpisano ręcznie).
    public var point: BoardPoint?
    public var input: InputKind

    public init(player: PlayerID, hit: DartHit, point: BoardPoint?, input: InputKind) {
        self.player = player
        self.hit = hit
        self.point = point
        self.input = input
    }
}

/// Mecz rzutek w trybie pass & play (1–4 graczy, jeden zegarek przekazywany z ręki do ręki).
///
/// Łączy profile graczy (nadgarstek, kalibracja, poziom), model rzutu i wybrany wariant
/// (X01, Cricket, Around the Clock). Stan jest `Codable`, więc mecz da się zapisać i wznowić,
/// a cofanie to stos stanów.
public struct DartsMatch: Sendable, Hashable, Codable {
    public private(set) var players: [PlayerProfile]
    public let game: DartsGame
    public var model: DartThrowModel
    public private(set) var state: DartsGameState
    /// Rzutki bieżącej tury z miejscem trafienia (do rysowania na tarczy).
    public private(set) var landings: [DartLanding] = []
    /// Ostatnia zakończona tura z miejscami trafień (podgląd przy zmianie gracza).
    public private(set) var previousTurnLandings: [DartLanding] = []
    /// Wszystkie rzutki meczu po kolei.
    public private(set) var log: [DartRecord] = []
    private var undoStack: [Snapshot] = []
    private var rng: SeededRandom

    public static let maxUndo = 30

    private struct Snapshot: Sendable, Hashable, Codable {
        var state: DartsGameState
        var landings: [DartLanding]
        var previousTurnLandings: [DartLanding]
        var logCount: Int
        var rng: SeededRandom
    }

    public enum MatchError: Error, Equatable {
        case playerCount(Int)
        case duplicatePlayers
    }

    public init(
        players: [PlayerProfile],
        game: DartsGame = .x01(X01Rules()),
        model: DartThrowModel = DartThrowModel(),
        seed: UInt64 = UInt64.random(in: 0...UInt64.max)
    ) throws {
        guard ModuleCatalog.darts.playerRange.contains(players.count) else {
            throw MatchError.playerCount(players.count)
        }
        guard Set(players.map(\.id)).count == players.count else { throw MatchError.duplicatePlayers }
        self.players = players
        self.game = game
        self.model = model
        self.state = game.start(players: players.map(\.id))
        self.rng = SeededRandom(seed: seed)
    }

    /// Wygodny konstruktor dla X01.
    public init(players: [PlayerProfile], rules: X01Rules, model: DartThrowModel = DartThrowModel(), seed: UInt64) throws {
        try self.init(players: players, game: .x01(rules), model: model, seed: seed)
    }

    // MARK: - Odczyt

    public var currentIndex: Int { state.turn.currentIndex }
    public var currentPlayer: PlayerProfile { players[currentIndex] }
    public var winner: PlayerProfile? { state.winner.flatMap { id in players.first { $0.id == id } } }
    public var isFinished: Bool { state.winner != nil }
    public var canUndo: Bool { !undoStack.isEmpty }
    public var round: Int { state.turn.round }
    public var dartsLeftInTurn: Int { game.throwsPerTurn - state.dartsThisTurn.count }

    public func index(of player: PlayerProfile) -> Int? {
        players.firstIndex { $0.id == player.id }
    }

    /// X01: punkty do zera (nil w innych wariantach).
    public func remaining(for player: PlayerProfile) -> Int? {
        guard let x01 = state.x01, let index = index(of: player) else { return nil }
        return x01.remaining[index]
    }

    /// Podpowiedź zamknięcia dla bieżącego gracza (tylko X01; nil, gdy nie da się w tej turze).
    public var checkoutHint: [DartHit]? {
        guard !isFinished, case .x01(let rules) = game, let x01 = state.x01 else { return nil }
        let index = currentIndex
        guard x01.opened[index] else { return nil }
        return rules.checkout(for: x01.remaining[index], dartsLeft: dartsLeftInTurn)
    }

    /// Bieżący cel w Around the Clock (nil w innych wariantach albo po ukończeniu).
    public func clockTarget(for player: PlayerProfile) -> Int? {
        guard case .aroundTheClock(let rules) = game, let s = state.aroundTheClock, let index = index(of: player) else {
            return nil
        }
        return rules.target(for: index, in: s)
    }

    // MARK: - Rzuty

    /// Rzut z zegarka: kalibracja i poziom bieżącego gracza.
    @discardableResult
    public mutating func throwDart(_ event: ThrowEvent) -> (landing: DartLanding, notices: [GameNotice]) {
        let player = currentPlayer
        let landing = model.land(
            event,
            calibration: player.calibration(for: .flick),
            difficulty: player.difficulty,
            using: &rng
        )
        return (landing, record(landing, input: .watch))
    }

    /// Rzut z dotyku: celowanie w punkt tarczy, rozrzut według poziomu gracza.
    @discardableResult
    public mutating func throwDart(aimingAt point: BoardPoint) -> (landing: DartLanding, notices: [GameNotice]) {
        let landing = model.land(aimingAt: point, difficulty: currentPlayer.difficulty, using: &rng)
        return (landing, record(landing, input: .touch))
    }

    /// Ręczne wpisanie trafienia (np. poprawka po źle rozpoznanym rzucie).
    @discardableResult
    public mutating func record(hit: DartHit) -> [GameNotice] {
        let point = model.board.center(of: hit) ?? BoardPoint(x: 0, y: -(model.board.doubleOuterRadius + 60))
        return record(DartLanding(aim: point, point: point, hit: hit, spread: 0), input: .replay, manual: true)
    }

    private mutating func record(_ landing: DartLanding, input: InputKind, manual: Bool = false) -> [GameNotice] {
        guard !isFinished else { return [.message("Gra zakończona")] }
        undoStack.append(Snapshot(
            state: state,
            landings: landings,
            previousTurnLandings: previousTurnLandings,
            logCount: log.count,
            rng: rng
        ))
        if undoStack.count > Self.maxUndo { undoStack.removeFirst() }
        log.append(DartRecord(player: currentPlayer.id, hit: landing.hit, point: manual ? nil : landing.point, input: input))
        let step = game.apply(landing.hit, to: state)
        state = step.state
        landings.append(landing)
        if step.notices.contains(where: { if case .turnEnded = $0 { true } else { false } }) {
            previousTurnLandings = landings
            landings = []
        }
        return step.notices
    }

    /// Cofa ostatnią rzutkę (także przez granicę tury i po zakończeniu gry).
    public mutating func undo() {
        guard let snapshot = undoStack.popLast() else { return }
        state = snapshot.state
        landings = snapshot.landings
        previousTurnLandings = snapshot.previousTurnLandings
        log.removeLast(log.count - snapshot.logCount)
        rng = snapshot.rng
    }

    /// Aktualizacja profilu w trakcie gry (np. kalibracja po kilku turach).
    public mutating func update(_ profile: PlayerProfile) {
        guard let index = players.firstIndex(where: { $0.id == profile.id }) else { return }
        players[index] = profile
    }

    /// Nowy mecz z tymi samymi graczami i wariantem; zaczyna kolejny gracz (rotacja rozpoczynającego).
    public func rematch(seed: UInt64 = UInt64.random(in: 0...UInt64.max)) throws -> DartsMatch {
        let rotated = Array(players.dropFirst()) + players.prefix(1)
        return try DartsMatch(players: rotated, game: game, model: model, seed: seed)
    }
}
