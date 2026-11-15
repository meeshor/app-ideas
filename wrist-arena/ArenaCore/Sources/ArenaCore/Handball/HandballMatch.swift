import Foundation
import WristKit

/// Tryb konkursu rzutów karnych.
public enum HandballMode: Sendable, Hashable, Codable {
    /// 1–4 rzucających przeciw bramkarzowi AI.
    case versusAI(KeeperLevel)
    /// Dwóch graczy na zmianę: jeden rzuca, drugi broni (wybiera strefę w ukryciu na telefonie).
    case duel
}

/// Jedna próba rzutu karnego.
public struct HandballAttempt: Sendable, Hashable, Codable {
    public var shooter: PlayerID
    /// Bramkarz-człowiek (tryb `duel`) albo nil (AI).
    public var keeper: PlayerID?
    public var feints: Int
    public var shot: HandballShot
    public var keeperAction: KeeperAction
    public var outcome: ShotOutcome
    public var input: InputKind

    public init(
        shooter: PlayerID,
        keeper: PlayerID?,
        feints: Int,
        shot: HandballShot,
        keeperAction: KeeperAction,
        outcome: ShotOutcome,
        input: InputKind
    ) {
        self.shooter = shooter
        self.keeper = keeper
        self.feints = feints
        self.shot = shot
        self.keeperAction = keeperAction
        self.outcome = outcome
        self.input = input
    }
}

/// Konkurs rzutów karnych (pass & play): kolejno po jednym rzucie, `shotsPerPlayer` w regulaminie,
/// potem dogrywka pełnymi kolejkami do pierwszej różnicy. Mecz rozstrzyga się wcześniej,
/// gdy nikt nie może już dogonić lidera.
public struct HandballMatch: Sendable, Hashable, Codable {
    public private(set) var players: [PlayerProfile]
    public let mode: HandballMode
    public let shotsPerPlayer: Int
    public var model: HandballModel
    public private(set) var attempts: [HandballAttempt] = []
    /// Zwody w bieżącej próbie (zerowane po rzucie).
    public private(set) var pendingFeints = 0
    /// Strefa wybrana przez bramkarza-człowieka w bieżącej próbie (tryb `duel`).
    public private(set) var keeperChoice: GoalZone?
    public private(set) var winner: PlayerID?
    private var undoStack: [Snapshot] = []
    private var rng: SeededRandom

    private struct Snapshot: Sendable, Hashable, Codable {
        var attempts: [HandballAttempt]
        var pendingFeints: Int
        var keeperChoice: GoalZone?
        var winner: PlayerID?
        var rng: SeededRandom
    }

    public enum MatchError: Error, Equatable {
        case playerCount(Int)
        case duplicatePlayers
    }

    public static let playerRange = 1...4

    public init(
        players: [PlayerProfile],
        mode: HandballMode = .versusAI(.regular),
        shotsPerPlayer: Int = 5,
        model: HandballModel = HandballModel(),
        seed: UInt64 = UInt64.random(in: 0...UInt64.max)
    ) throws {
        let range = mode == .duel ? 2...2 : Self.playerRange
        guard range.contains(players.count) else { throw MatchError.playerCount(players.count) }
        guard Set(players.map(\.id)).count == players.count else { throw MatchError.duplicatePlayers }
        self.players = players
        self.mode = mode
        self.shotsPerPlayer = shotsPerPlayer
        self.model = model
        self.rng = SeededRandom(seed: seed)
    }

    // MARK: - Odczyt

    public var isFinished: Bool { winner != nil }
    public var canUndo: Bool { !undoStack.isEmpty }
    public var currentIndex: Int { attempts.count % players.count }
    public var currentShooter: PlayerProfile { players[currentIndex] }

    /// Bramkarz bieżącej próby w trybie `duel` (drugi gracz).
    public var currentKeeper: PlayerProfile? {
        guard mode == .duel else { return nil }
        return players[(currentIndex + 1) % players.count]
    }

    /// Kolejka (1 = pierwszy rzut każdego gracza).
    public var round: Int { attempts.count / players.count + 1 }
    public var isSuddenDeath: Bool { round > shotsPerPlayer }

    /// Czy czekamy na wybór strefy przez bramkarza-człowieka.
    public var needsKeeperChoice: Bool { mode == .duel && keeperChoice == nil && !isFinished }

    public func goals(for player: PlayerProfile) -> Int {
        attempts.filter { $0.shooter == player.id && $0.outcome.isGoal }.count
    }

    public func attempts(for player: PlayerProfile) -> [HandballAttempt] {
        attempts.filter { $0.shooter == player.id }
    }

    // MARK: - Akcje

    /// Zwód rozpoznany na zegarku (przed rzutem).
    public mutating func registerFeint() {
        guard !isFinished else { return }
        pendingFeints += 1
    }

    /// Bramkarz-człowiek wybiera strefę (w ukryciu przed rzucającym).
    public mutating func chooseKeeperZone(_ zone: GoalZone) {
        guard mode == .duel, !isFinished else { return }
        keeperChoice = zone
    }

    /// Rzut z zegarka (zdarzenie bez `isFeint`; zwody zgłaszaj przez `registerFeint`).
    @discardableResult
    public mutating func shoot(_ event: ThrowEvent) -> HandballAttempt? {
        guard !event.isFeint else {
            registerFeint()
            return nil
        }
        let shooter = currentShooter
        let shot = model.shot(event, calibration: shooter.calibration(for: .overarm), difficulty: shooter.difficulty, using: &rng)
        return resolve(shot, input: .watch)
    }

    /// Rzut z dotyku: celowanie w punkt bramki.
    @discardableResult
    public mutating func shoot(aimingAt point: GoalPoint) -> HandballAttempt? {
        let shot = model.shot(aim: point, difficulty: currentShooter.difficulty, using: &rng)
        return resolve(shot, input: .touch)
    }

    public mutating func undo() {
        guard let snapshot = undoStack.popLast() else { return }
        attempts = snapshot.attempts
        pendingFeints = snapshot.pendingFeints
        keeperChoice = snapshot.keeperChoice
        winner = snapshot.winner
        rng = snapshot.rng
    }

    public mutating func update(_ profile: PlayerProfile) {
        guard let index = players.firstIndex(where: { $0.id == profile.id }) else { return }
        players[index] = profile
    }

    // MARK: - Rozstrzygnięcie

    private mutating func resolve(_ shot: HandballShot, input: InputKind) -> HandballAttempt? {
        guard !isFinished, !needsKeeperChoice else { return nil }
        undoStack.append(Snapshot(attempts: attempts, pendingFeints: pendingFeints, keeperChoice: keeperChoice, winner: winner, rng: rng))
        if undoStack.count > 30 { undoStack.removeFirst() }

        let (action, outcome): (KeeperAction, ShotOutcome)
        switch mode {
        case .versusAI(let level):
            (action, outcome) = model.keeperAI(level: level, feints: pendingFeints, shot: shot, using: &rng)
        case .duel:
            (action, outcome) = model.humanKeeper(zone: keeperChoice ?? GoalZone(column: 1, row: 1), shot: shot, using: &rng)
        }
        let attempt = HandballAttempt(
            shooter: currentShooter.id,
            keeper: currentKeeper?.id,
            feints: pendingFeints,
            shot: shot,
            keeperAction: action,
            outcome: outcome,
            input: input
        )
        attempts.append(attempt)
        pendingFeints = 0
        keeperChoice = nil
        winner = decideWinner()
        return attempt
    }

    /// Lider, którego nikt już nie dogoni (regulamin), albo jedyny lider po pełnej kolejce dogrywki.
    private func decideWinner() -> PlayerID? {
        let scores = players.map { goals(for: $0) }
        let taken = players.map { player in attempts.filter { $0.shooter == player.id }.count }
        let completeRound = attempts.count.isMultiple(of: players.count)

        if players.count == 1 {
            return taken[0] >= shotsPerPlayer ? players[0].id : nil
        }
        if taken.allSatisfy({ $0 <= shotsPerPlayer }) {
            let possible = players.indices.map { scores[$0] + max(0, shotsPerPlayer - taken[$0]) }
            for leader in players.indices {
                let others = players.indices.filter { $0 != leader }
                if others.allSatisfy({ possible[$0] < scores[leader] }) { return players[leader].id }
            }
            if !(completeRound && taken[0] == shotsPerPlayer) { return nil }
        } else if !completeRound {
            return nil
        }
        // Koniec regulaminu albo pełna kolejka dogrywki: jedyny lider wygrywa.
        guard let best = scores.max(), scores.filter({ $0 == best }).count == 1,
              let index = scores.firstIndex(of: best) else { return nil }
        return players[index].id
    }
}
