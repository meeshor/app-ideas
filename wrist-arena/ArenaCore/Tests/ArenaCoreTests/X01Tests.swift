import Foundation
import Testing
import WristKit
@testable import ArenaCore

@Suite("X01 (501)")
struct X01Tests {
    let a = UUID()
    let b = UUID()

    private func play(_ hits: [DartHit], rules: X01Rules = X01Rules(), state: X01State? = nil) -> (X01State, [GameNotice]) {
        var state = state ?? rules.start(players: [a, b])
        var notices: [GameNotice] = []
        for hit in hits {
            let step = rules.apply(hit, to: state)
            state = step.state
            notices += step.notices
        }
        return (state, notices)
    }

    @Test func scoresAndPassesTurnAfterThreeDarts() {
        let (state, notices) = play([.triple(20), .triple(20), .triple(20)])
        #expect(state.remaining == [321, 501])
        #expect(state.currentPlayer == b)
        #expect(notices.last == .turnEnded(next: b))
        #expect(state.history.count == 1)
        #expect(state.history[0].points == 180)
        #expect(state.threeDartAverage(for: a) == 180)
    }

    @Test func bustRevertsTurnAndPassesTurn() {
        let rules = X01Rules(startScore: 101)
        let (state, notices) = play([.triple(20), .triple(20)], rules: rules)
        #expect(state.remaining == [101, 101])
        #expect(notices.contains(.bust(player: a)))
        #expect(state.currentPlayer == b)
        #expect(state.history.last?.bust == true)
        #expect(state.pointsScored[0] == 0)
        #expect(state.dartsThrown[0] == 2)
    }

    @Test func leavingOneIsBustWithDoubleOut() {
        let rules = X01Rules(startScore: 21)
        let (state, notices) = play([.single(20)], rules: rules)
        #expect(state.remaining[0] == 21)
        #expect(notices.contains(.bust(player: a)))
    }

    @Test func finishingOnSingleIsBustWithDoubleOut() {
        let rules = X01Rules(startScore: 40)
        let (bust, _) = play([.single(20), .single(20)], rules: rules)
        #expect(bust.remaining[0] == 40)
        #expect(bust.winner == nil)

        let (win, notices) = play([.double(20)], rules: rules)
        #expect(win.winner == a)
        #expect(notices.last == .finished(winner: a))
    }

    @Test func bullseyeCountsAsDouble() {
        let (state, _) = play([.innerBull], rules: X01Rules(startScore: 50))
        #expect(state.winner == a)
    }

    @Test func straightOutAllowsSingleFinish() {
        let (state, _) = play([.single(20), .single(20)], rules: X01Rules(startScore: 40, doubleOut: false))
        #expect(state.winner == a)
    }

    @Test func doubleInIgnoresPointsUntilDouble() {
        let rules = X01Rules(startScore: 301, doubleIn: true)
        let (state, _) = play([.triple(20), .double(10), .single(5)], rules: rules)
        #expect(state.remaining[0] == 301 - 20 - 5)
        #expect(state.opened == [true, false])
    }

    @Test func noMoreThrowsAfterWin() {
        let rules = X01Rules(startScore: 40)
        let (won, _) = play([.double(20)], rules: rules)
        let step = rules.apply(.triple(20), to: won)
        #expect(step.state == won)
    }

    @Test func checkoutSuggestions() {
        let rules = X01Rules()
        #expect(rules.checkout(for: 170) == [.triple(20), .triple(20), .innerBull])
        #expect(rules.checkout(for: 40) == [.double(20)])
        #expect(rules.checkout(for: 50) == [.innerBull])
        #expect(rules.checkout(for: 32, dartsLeft: 1) == [.double(16)])
        #expect(rules.checkout(for: 169) == nil, "169 nie da się zamknąć trzema rzutkami")
        #expect(rules.checkout(for: 1) == nil)
        #expect(rules.checkout(for: 41, dartsLeft: 1) == nil)
        for score in 2...170 {
            guard let path = rules.checkout(for: score) else { continue }
            #expect(path.reduce(0) { $0 + $1.score } == score)
            #expect(path.last?.isDouble == true)
        }
        #expect(X01Rules(doubleOut: false).checkout(for: 7, dartsLeft: 1) == [.single(7)])
    }
}

@Suite("Model rzutu")
struct DartThrowModelTests {
    let model = DartThrowModel()

    private func event(yaw: Double = 0, pitch: Double = 0, speed: Double = 4.2, spin: Double = 0, jerk: Double = 0) -> ThrowEvent {
        ThrowEvent(kind: .flick, speed: speed, pitch: pitch, yaw: yaw, spin: spin, jerk: jerk, watchTimestamp: 0)
    }

    @Test func centeredThrowAimsAtBull() throws {
        let aim = try #require(model.aimPoint(for: event(), calibration: .none))
        #expect(abs(aim.x) < 1e-9 && abs(aim.y) < 1e-9)
    }

    @Test func directionsMapToBoard() throws {
        let right = try #require(model.aimPoint(for: event(yaw: 0.05), calibration: .none))
        let up = try #require(model.aimPoint(for: event(pitch: 0.05), calibration: .none))
        #expect(right.x > 50 && abs(right.y) < 1e-9)
        #expect(up.y > 50 && abs(up.x) < 1e-9)
    }

    @Test func calibrationShiftsAim() throws {
        let calibration = Calibration(yawOffset: 0.02, pitchOffset: -0.3, sampleCount: 3)
        let aim = try #require(model.aimPoint(for: event(yaw: 0.02, pitch: -0.3), calibration: calibration))
        #expect(abs(aim.x) < 1e-9 && abs(aim.y) < 1e-9)
    }

    @Test func slowThrowDropsAndTooSlowMisses() throws {
        let slow = try #require(model.aimPoint(for: event(speed: 4.2 * 0.8), calibration: .none))
        #expect(abs(slow.y + model.tuning.dropAtEightyPercent) < 1e-9)
        #expect(model.aimPoint(for: event(speed: 1), calibration: .none) == nil)
        var rng = SeededRandom(seed: 1)
        #expect(model.land(event(speed: 1), calibration: .none, difficulty: .normal, using: &rng).hit == .miss)
    }

    @Test func jerkAndSpinWidenSpread() {
        let base = model.spread(for: event(), difficulty: .normal)
        #expect(model.spread(for: event(jerk: 2), difficulty: .normal) > base)
        #expect(model.spread(for: event(spin: 6), difficulty: .normal) > base)
        #expect(model.spread(for: event(), difficulty: .pro) > model.spread(for: event(), difficulty: .easy))
    }

    @Test func scatterIsDeterministicAndRoughlyCalibrated() {
        var rng = SeededRandom(seed: 7)
        let landings = (0..<2000).map { _ in model.land(event(), calibration: .none, difficulty: .normal, using: &rng) }
        let meanX = landings.map(\.point.x).reduce(0, +) / 2000
        let meanR2 = landings.map { $0.point.radius * $0.point.radius }.reduce(0, +) / 2000
        let sigma = model.tuning.baseSpread(for: .normal)
        #expect(abs(meanX) < 1.5)
        #expect(abs(meanR2 / (2 * sigma * sigma) - 1) < 0.1)

        var again = SeededRandom(seed: 7)
        #expect(model.land(event(), calibration: .none, difficulty: .normal, using: &again) == landings[0])
    }
}
