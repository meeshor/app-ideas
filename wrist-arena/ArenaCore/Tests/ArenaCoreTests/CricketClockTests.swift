import Foundation
import Testing
import WristKit
@testable import ArenaCore

private func play<R: GameRules>(_ rules: R, _ hits: [DartHit], players: [PlayerID]) -> (R.State, [GameNotice])
where R.Shot == DartHit {
    var state = rules.start(players: players)
    var notices: [GameNotice] = []
    for hit in hits {
        let step = rules.apply(hit, to: state)
        state = step.state
        notices += step.notices
    }
    return (state, notices)
}

@Suite("Cricket")
struct CricketTests {
    let a = UUID()
    let b = UUID()
    let rules = CricketRules()

    @Test func marksCloseAndScore() {
        // A: T20 (zamyka), S20 → 20 pkt, bo B nie zamknął.
        let (state, notices) = play(rules, [.triple(20), .single(20), .single(1)], players: [a, b])
        #expect(state.isClosed(player: 0, target: 0))
        #expect(state.points == [20, 0])
        #expect(state.marksScored[0] == 4)
        #expect(state.currentPlayerIndex == 1)
        #expect(notices.contains(.scored(player: a, points: 20)))
        #expect(state.turnMarksHistory[0] == [4])
    }

    @Test func noPointsWhenEveryoneClosed() {
        let hits: [DartHit] = [.triple(20), .miss, .miss, .triple(20), .miss, .miss, .triple(20)]
        let (state, _) = play(rules, hits, players: [a, b])
        #expect(state.points == [0, 0])
    }

    @Test func outsideNumbersAndBulls() {
        #expect(CricketRules.marks(for: .triple(14)) == 0)
        #expect(CricketRules.marks(for: .innerBull) == 2)
        #expect(CricketRules.marks(for: .outerBull) == 1)
        #expect(CricketRules.marks(for: .miss) == 0)
    }

    @Test func cutThroatGivesPointsToOpponents() {
        let rules = CricketRules(cutThroat: true)
        let (state, _) = play(rules, [.triple(19), .triple(19)], players: [a, b])
        #expect(state.points == [0, 57])
    }

    /// Gracz zamyka wszystko i prowadzi → wygrywa w trakcie tury.
    @Test func winsWhenAllClosedAndAhead() {
        var hits: [DartHit] = []
        for number in [20, 19, 18, 17, 16, 15] {
            hits += [.triple(number), .miss, .miss] // A
            hits += [.miss, .miss, .miss]           // B
        }
        hits += [.innerBull, .outerBull]
        let (state, notices) = play(rules, hits, players: [a, b])
        #expect(state.winner == a)
        #expect(notices.last == .finished(winner: a))
        #expect(state.closedAll(player: 0))
    }

    @Test func closedButBehindDoesNotWin() {
        // B zdobywa punkty na 20, A zamyka wszystko, ale ma 0 pkt < B → gra trwa.
        var hits: [DartHit] = [.miss, .miss, .miss, .triple(20), .triple(20), .miss]
        for number in [20, 19, 18, 17, 16, 15] {
            hits += [.triple(number), .miss, .miss]
            hits += [.miss, .miss, .miss]
        }
        hits += [.innerBull, .outerBull]
        let (state, _) = play(rules, hits, players: [a, b])
        #expect(state.closedAll(player: 0))
        #expect(state.points == [0, 60])
        #expect(state.winner == nil)
    }

    @Test func roundLimitPicksBestScore() {
        let rules = CricketRules(roundLimit: 2)
        let hits: [DartHit] = [.triple(20), .single(20), .miss, .miss, .miss, .miss, .miss, .miss, .miss, .triple(19), .miss, .miss]
        let (state, notices) = play(rules, hits, players: [a, b])
        #expect(state.winner == a)
        #expect(notices.last == .finished(winner: a))
    }

    @Test func singlePlayerWinsByClosing() {
        var hits: [DartHit] = []
        for number in [20, 19, 18, 17, 16, 15] { hits += [.triple(number)] }
        hits += [.innerBull, .outerBull]
        let (state, _) = play(CricketRules(roundLimit: nil), hits, players: [a])
        #expect(state.winner == a)
        // 21 znaków w 8 rzutkach → 7,875 znaku na rundę.
        #expect(state.marksPerRound(player: 0) == 21.0 / 8 * 3)
    }
}

extension CricketState {
    var currentPlayerIndex: Int { turn.currentIndex }
}

@Suite("Around the Clock")
struct AroundTheClockTests {
    let a = UUID()
    let b = UUID()

    @Test func advancesOnlyOnTarget() {
        let rules = AroundTheClockRules()
        let (state, _) = play(rules, [.single(1), .single(3), .triple(2)], players: [a, b])
        #expect(state.progress == [2, 0])
        #expect(rules.target(for: 0, in: state) == 3)
        #expect(state.hits[0] == 2)
        #expect(state.accuracy(player: 0) == 2.0 / 3.0)
    }

    @Test func multiplierVariantSkipsAhead() {
        let rules = AroundTheClockRules(advanceByMultiplier: true)
        let (state, _) = play(rules, [.double(1), .triple(3)], players: [a])
        #expect(state.progress[0] == 5)
    }

    @Test func finishesOnBull() {
        let rules = AroundTheClockRules()
        let hits = (1...20).map(DartHit.single) + [.outerBull]
        let (state, notices) = play(rules, hits, players: [a])
        #expect(state.winner == a)
        #expect(notices.last == .finished(winner: a))
        #expect(state.dartsThrown[0] == 21)
    }

    @Test func finishesOnTwentyWithoutBull() {
        let rules = AroundTheClockRules(finishOnBull: false)
        let (state, _) = play(rules, (1...20).map(DartHit.single), players: [a])
        #expect(state.winner == a)
    }
}

@Suite("Warianty w meczu i statystyki")
struct VariantMatchStatsTests {
    let players = ["Ola", "Bartek"].map { PlayerProfile(name: $0) }

    @Test func cricketMatchWithUndo() throws {
        var match = try DartsMatch(players: players, game: .cricket(CricketRules()), seed: 1)
        match.record(hit: .triple(20))
        match.record(hit: .single(20))
        #expect(match.state.cricket?.points == [20, 0])
        match.undo()
        #expect(match.state.cricket?.points == [0, 0])
        #expect(match.log.count == 1)
        #expect(match.remaining(for: players[0]) == nil)
        #expect(match.checkoutHint == nil)
    }

    @Test func clockTargetFollowsProgress() throws {
        var match = try DartsMatch(players: players, game: .aroundTheClock(AroundTheClockRules()), seed: 1)
        #expect(match.clockTarget(for: players[0]) == 1)
        match.record(hit: .single(1))
        #expect(match.clockTarget(for: players[0]) == 2)
        #expect(match.clockTarget(for: players[1]) == 1)
    }

    @Test func x01StatsFromMatch() throws {
        var match = try DartsMatch(players: players, rules: X01Rules(startScore: 101), seed: 1)
        for hit: DartHit in [.triple(20), .single(1), .miss] { match.record(hit: hit) }   // Ola 61
        for hit: DartHit in [.triple(20), .triple(20)] { match.record(hit: hit) }  // Bartek bust drugą rzutką (120 > 101)
        for hit: DartHit in [.single(20), .double(10)] { match.record(hit: hit) }         // Ola zamyka 40
        let stats = match.stats
        #expect(stats[0].won)
        #expect(stats[0].x01Points == 101)
        #expect(stats[0].bestTurn == 61)
        #expect(stats[0].checkout == 40)
        #expect(stats[0].triples == 1)
        #expect(stats[0].doubles == 1)
        #expect(stats[0].misses == 1)
        #expect(stats[1].busts == 1)
        #expect(stats[1].x01Points == 0)
        #expect(!stats[1].won)

        var lifetime = PlayerStats()
        lifetime.add(stats[0], game: match.game)
        lifetime.add(stats[0], game: match.game)
        #expect(lifetime.matches == 2)
        #expect(lifetime.wins == 2)
        #expect(lifetime.highestCheckout == 40)
        #expect(lifetime.x01Average == stats[0].x01Average)
    }

    @Test func cricketAndClockStats() throws {
        var cricket = try DartsMatch(players: players, game: .cricket(CricketRules()), seed: 1)
        for hit: DartHit in [.triple(20), .triple(19), .single(18)] { cricket.record(hit: hit) }
        let cricketStats = cricket.stats[0]
        #expect(cricketStats.cricketMarks == 7)
        #expect(cricketStats.marksPerRound == 7)
        #expect(cricketStats.bestCricketTurnMarks == 7)

        var clock = try DartsMatch(players: [players[0]], game: .aroundTheClock(AroundTheClockRules(finishOnBull: false)), seed: 1)
        for number in 1...20 { clock.record(hit: .single(number)) }
        var lifetime = PlayerStats()
        lifetime.add(clock.stats[0], game: clock.game)
        #expect(lifetime.bestClockFinish == 20)
        #expect(lifetime.clockAccuracy == 1)
    }

    @Test func rematchRotatesStarter() throws {
        let match = try DartsMatch(players: players, game: .cricket(CricketRules()), seed: 1)
        let next = try match.rematch(seed: 2)
        #expect(next.currentPlayer.name == "Bartek")
        #expect(next.game == match.game)
    }

    @Test func variantStateRoundTripsThroughJSON() throws {
        var match = try DartsMatch(players: players, game: .cricket(CricketRules(cutThroat: true)), seed: 3)
        match.throwDart(aimingAt: BoardPoint(x: 0, y: 103))
        let decoded = try JSONDecoder().decode(DartsMatch.self, from: JSONEncoder().encode(match))
        #expect(decoded == match)
    }
}
