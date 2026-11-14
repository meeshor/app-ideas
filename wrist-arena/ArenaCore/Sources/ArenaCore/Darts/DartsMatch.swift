import Foundation
import WristKit

/// Mecz rzutek w trybie pass & play (2–4 graczy, jeden zegarek przekazywany z ręki do ręki).
///
/// Łączy profile graczy (nadgarstek, kalibracja, poziom), model rzutu i reguły X01.
/// Stan jest `Codable`, więc mecz da się zapisać i wznowić, a cofanie to stos stanów.
public struct DartsMatch: Sendable, Hashable, Codable {
    public private(set) var players: [PlayerProfile]
    public let rules: X01Rules
    public var model: DartThrowModel
    public private(set) var state: X01State
    /// Rzutki bieżącej tury z miejscem trafienia (do rysowania na tarczy).
    public private(set) var landings: [DartLanding] = []
    /// Ostatnia zakończona tura z miejscami trafień (podgląd przy zmianie gracza).
    public private(set) var previousTurnLandings: [DartLanding] = []
    private var undoStack: [Snapshot] = []
    private var rng: SeededRandom

    public static let maxUndo = 30

    private struct Snapshot: Sendable, Hashable, Codable {
        var state: X01State
        var landings: [DartLanding]
        var previousTurnLandings: [DartLanding]
        var rng: SeededRandom
    }

    public enum MatchError: Error, Equatable {
        case playerCount(Int)
        case duplicatePlayers
    }

    public init(
        players: [PlayerProfile],
        rules: X01Rules = X01Rules(),
        model: DartThrowModel = DartThrowModel(),
        seed: UInt64 = UInt64.random(in: 0...UInt64.max)
    ) throws {
        guard ModuleCatalog.darts.playerRange.contains(players.count) else {
            throw MatchError.playerCount(players.count)
        }
        guard Set(players.map(\.id)).count == players.count else { throw MatchError.duplicatePlayers }
        self.players = players
        self.rules = rules
        self.model = model
        self.state = rules.start(players: players.map(\.id))
        self.rng = SeededRandom(seed: seed)
    }

    // MARK: - Odczyt

    public var currentPlayer: PlayerProfile { players[state.turn.currentIndex] }
    public var winner: PlayerProfile? { state.winner.flatMap { id in players.first { $0.id == id } } }
    public var isFinished: Bool { state.winner != nil }
    public var canUndo: Bool { !undoStack.isEmpty }

    public func remaining(for player: PlayerProfile) -> Int {
        state.remaining(for: player.id) ?? rules.startScore
    }

    /// Podpowiedź zamknięcia dla bieżącego gracza (nil, gdy nie da się w tej turze).
    public var checkoutHint: [DartHit]? {
        guard !isFinished else { return nil }
        let index = state.turn.currentIndex
        guard state.opened[index] else { return nil }
        return rules.checkout(for: state.remaining[index], dartsLeft: state.dartsLeftInTurn)
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
        return (landing, record(landing))
    }

    /// Rzut z dotyku: celowanie w punkt tarczy, rozrzut według poziomu gracza.
    @discardableResult
    public mutating func throwDart(aimingAt point: BoardPoint) -> (landing: DartLanding, notices: [GameNotice]) {
        let landing = model.land(aimingAt: point, difficulty: currentPlayer.difficulty, using: &rng)
        return (landing, record(landing))
    }

    /// Ręczne wpisanie trafienia (np. poprawka po źle rozpoznanym rzucie).
    @discardableResult
    public mutating func record(hit: DartHit) -> [GameNotice] {
        let point = model.board.center(of: hit) ?? BoardPoint(x: 0, y: -(model.board.doubleOuterRadius + 60))
        return record(DartLanding(aim: point, point: point, hit: hit, spread: 0))
    }

    private mutating func record(_ landing: DartLanding) -> [GameNotice] {
        guard !isFinished else { return [.message("Gra zakończona")] }
        undoStack.append(Snapshot(state: state, landings: landings, previousTurnLandings: previousTurnLandings, rng: rng))
        if undoStack.count > Self.maxUndo { undoStack.removeFirst() }
        let step = rules.apply(landing.hit, to: state)
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
        rng = snapshot.rng
    }

    /// Aktualizacja profilu w trakcie gry (np. kalibracja po kilku turach).
    public mutating func update(_ profile: PlayerProfile) {
        guard let index = players.firstIndex(where: { $0.id == profile.id }) else { return }
        players[index] = profile
    }
}
