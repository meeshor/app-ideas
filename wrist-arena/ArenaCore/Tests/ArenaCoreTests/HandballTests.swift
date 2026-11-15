import Foundation
import Testing
import WristKit
@testable import ArenaCore

@Suite("Ręczna: bramka i model")
struct HandballModelTests {
    let goal = HandballGoal.standard
    let model = HandballModel()

    @Test func zonesAndFrame() {
        #expect(goal.zone(of: GoalPoint(x: -1.2, y: 0.2)) == GoalZone(column: 0, row: 0))
        #expect(goal.zone(of: GoalPoint(x: 0, y: 1)) == GoalZone(column: 1, row: 1))
        #expect(goal.zone(of: GoalPoint(x: 1.2, y: 1.8)) == GoalZone(column: 2, row: 2))
        #expect(goal.zone(of: GoalPoint(x: 2, y: 1)) == nil)
        #expect(goal.hitsFrame(GoalPoint(x: 1.5, y: 1)))
        #expect(goal.hitsFrame(GoalPoint(x: 0, y: 2.01)))
        #expect(!goal.hitsFrame(GoalPoint(x: 0, y: 1)))
        for zone in GoalZone.allCases {
            #expect(goal.zone(of: goal.center(of: zone)) == zone)
        }
        #expect(GoalZone(column: 0, row: 2).name == "lewy góra")
    }

    @Test func aimFollowsDirection() {
        func event(yaw: Double = 0, pitch: Double = 0, spin: Double = 0) -> ThrowEvent {
            ThrowEvent(kind: .overarm, speed: 9, pitch: pitch, yaw: yaw, spin: spin, watchTimestamp: 0)
        }
        let center = model.aimPoint(for: event(), calibration: .none)
        #expect(center == GoalPoint(x: 0, y: model.tuning.aimHeight))
        #expect(model.aimPoint(for: event(yaw: 0.1), calibration: .none).x > 0.4)
        #expect(model.aimPoint(for: event(pitch: -0.1), calibration: .none).y < 0.6)
        #expect(model.aimPoint(for: event(spin: 5), calibration: .none).x > 0.1)
        let calibrated = model.aimPoint(for: event(yaw: 0.05, pitch: 0.02), calibration: Calibration(yawOffset: 0.05, pitchOffset: 0.02))
        #expect(abs(calibrated.x) < 1e-9)
    }

    private func goalRate(level: KeeperLevel, feints: Int, aim: GoalPoint, speed: Double) -> Double {
        var rng = SeededRandom(seed: 5)
        var goals = 0
        let trials = 2000
        for _ in 0..<trials {
            let shot = HandballShot(aim: aim, point: aim, speedKmh: speed, spread: 0)
            if model.keeperAI(level: level, feints: feints, shot: shot, using: &rng).1 == .goal { goals += 1 }
        }
        return Double(goals) / Double(trials)
    }

    @Test func keeperSavesEasyShotsAndMissesHardOnes() {
        let middle = GoalPoint(x: 0.2, y: 0.9)
        let corner = GoalPoint(x: 1.3, y: 1.8)
        #expect(goalRate(level: .regular, feints: 0, aim: middle, speed: 60) < 0.25)
        #expect(goalRate(level: .regular, feints: 0, aim: corner, speed: 100) > 0.9)
        #expect(goalRate(level: .pro, feints: 0, aim: corner, speed: 70) < goalRate(level: .rookie, feints: 0, aim: corner, speed: 70) + 1e-9)
    }

    @Test func feintsFoolTheKeeper() {
        let middle = GoalPoint(x: 0.3, y: 1.0)
        let plain = goalRate(level: .regular, feints: 0, aim: middle, speed: 80)
        let oneFeint = goalRate(level: .regular, feints: 1, aim: middle, speed: 80)
        let twoFeints = goalRate(level: .regular, feints: 2, aim: middle, speed: 80)
        #expect(oneFeint > plain + 0.15)
        #expect(twoFeints > oneFeint)
    }

    @Test func outcomesOutsideTheGoal() {
        var rng = SeededRandom(seed: 1)
        let wide = HandballShot(aim: GoalPoint(x: 2.5, y: 1), point: GoalPoint(x: 2.5, y: 1), speedKmh: 90, spread: 0)
        let post = HandballShot(aim: GoalPoint(x: 1.5, y: 1), point: GoalPoint(x: 1.5, y: 1), speedKmh: 90, spread: 0)
        #expect(model.keeperAI(level: .rookie, feints: 0, shot: wide, using: &rng).1 == .miss)
        #expect(model.keeperAI(level: .rookie, feints: 0, shot: post, using: &rng).1 == .post)
    }

    @Test func humanKeeperZone() {
        var rng = SeededRandom(seed: 2)
        let corner = GoalPoint(x: -1.1, y: 0.4)
        let shot = HandballShot(aim: corner, point: corner, speedKmh: 90, spread: 0)
        var saves = 0
        for _ in 0..<500 where model.humanKeeper(zone: GoalZone(column: 0, row: 0), shot: shot, using: &rng).1 == .saved {
            saves += 1
        }
        #expect(saves > 350)
        #expect(model.humanKeeper(zone: GoalZone(column: 2, row: 2), shot: shot, using: &rng).1 == .goal)
    }
}

@Suite("Ręczna: konkurs rzutów karnych")
struct HandballMatchTests {
    let players = ["Ola", "Bartek", "Ania"].map { PlayerProfile(name: $0) }

    /// Model bez rozrzutu i z bramkarzem, który nic nie broni: wynik zależy tylko od celu.
    private var deterministic: HandballModel {
        var tuning = HandballTuning()
        tuning.spread = [.easy: 0, .normal: 0, .hard: 0, .pro: 0]
        tuning.reach = 0
        tuning.diveSpeed = 0
        tuning.humanKeeperReach = 0.6
        tuning.saveChance = 1
        return HandballModel(tuning: tuning)
    }

    private let inside = GoalPoint(x: 0.5, y: 1)
    private let wide = GoalPoint(x: 3, y: 1)

    @Test func modeLimits() {
        #expect(throws: HandballMatch.MatchError.playerCount(3)) { try HandballMatch(players: players, mode: .duel, seed: 1) }
        #expect((try? HandballMatch(players: players, seed: 1)) != nil)
    }

    @Test func earlyDecisionWhenNobodyCanCatchUp() throws {
        var match = try HandballMatch(players: Array(players.prefix(2)), shotsPerPlayer: 3, model: deterministic, seed: 1)
        // Ola trafia, Bartek pudłuje — po 2 kolejkach 2:0, Bartkowi zostaje 1 rzut → koniec.
        match.shoot(aimingAt: inside)
        match.shoot(aimingAt: wide)
        match.shoot(aimingAt: inside)
        #expect(!match.isFinished)
        match.shoot(aimingAt: wide)
        #expect(match.winner == players[0].id)
        #expect(match.goals(for: players[0]) == 2)
    }

    @Test func suddenDeathAfterTie() throws {
        var match = try HandballMatch(players: Array(players.prefix(2)), shotsPerPlayer: 2, model: deterministic, seed: 1)
        for _ in 0..<4 { match.shoot(aimingAt: inside) }
        #expect(!match.isFinished)
        #expect(match.isSuddenDeath)
        match.shoot(aimingAt: inside)
        #expect(!match.isFinished, "w dogrywce rozstrzyga pełna kolejka")
        match.shoot(aimingAt: wide)
        #expect(match.winner == players[0].id)
    }

    @Test func soloPracticeEndsAfterSeries() throws {
        var match = try HandballMatch(players: [players[0]], shotsPerPlayer: 3, model: deterministic, seed: 1)
        for _ in 0..<3 { match.shoot(aimingAt: inside) }
        #expect(match.isFinished)
        #expect(match.goals(for: players[0]) == 3)
    }

    @Test func duelNeedsHiddenKeeperChoice() throws {
        var match = try HandballMatch(players: Array(players.prefix(2)), mode: .duel, model: deterministic, seed: 1)
        #expect(match.currentKeeper?.name == "Bartek")
        #expect(match.needsKeeperChoice)
        let blocked = match.shoot(aimingAt: inside)
        #expect(blocked == nil)
        match.chooseKeeperZone(GoalZone(column: 2, row: 1))
        let first = match.shoot(aimingAt: inside)
        let saved = try #require(first)
        #expect(saved.outcome == .saved)
        #expect(saved.keeper == players[1].id)
        #expect(match.currentKeeper?.name == "Ola")
        match.chooseKeeperZone(GoalZone(column: 0, row: 0))
        let second = match.shoot(aimingAt: inside)
        #expect(second?.outcome == .goal)
    }

    @Test func feintsAreCountedAndUndoRestores() throws {
        var match = try HandballMatch(players: Array(players.prefix(2)), model: deterministic, seed: 1)
        let feint = ThrowEvent(kind: .overarm, speed: 3, pitch: 0, yaw: 0, isFeint: true, watchTimestamp: 0)
        let feintResult = match.shoot(feint)
        #expect(feintResult == nil)
        match.registerFeint()
        #expect(match.pendingFeints == 2)
        let shot = ThrowEvent(kind: .overarm, speed: 9, pitch: 0, yaw: 0.05, watchTimestamp: 1)
        let shotResult = match.shoot(shot)
        let attempt = try #require(shotResult)
        #expect(attempt.feints == 2)
        #expect(match.pendingFeints == 0)
        match.undo()
        #expect(match.attempts.isEmpty)
        #expect(match.pendingFeints == 2)
        let data = try JSONEncoder().encode(match)
        #expect(try JSONDecoder().decode(HandballMatch.self, from: data) == match)
    }

    /// Ruch ręki → OverarmThrowRecognizer → konkurs.
    @Test func endToEndFromMotion() throws {
        var motion = SyntheticMotion(elevation: 0.8, seed: 9)
        motion.hold(1)
        motion.feint()
        motion.hold(0.4)
        motion.overarm(.init(yawDeviation: 0.15))
        motion.hold(1.5)
        var recognizer = OverarmThrowRecognizer()
        let events = MotionReplayer(recording: motion.recording(label: "e2e")).events(&recognizer)
        var match = try HandballMatch(players: [players[0]], model: deterministic, seed: 1)
        var attempt: HandballAttempt?
        for event in events {
            if let result = match.shoot(event) { attempt = result }
        }
        let result = try #require(attempt)
        #expect(result.feints == 1)
        #expect(result.shot.speedKmh > 70)
        #expect(result.shot.aim.x > 0, "rzut w prawo")
    }
}
