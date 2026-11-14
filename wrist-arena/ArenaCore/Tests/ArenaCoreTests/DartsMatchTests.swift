import Foundation
import Testing
import WristKit
@testable import ArenaCore

@Suite("Mecz pass & play")
struct DartsMatchTests {
    let players = ["Ola", "Bartek", "Michał", "Ania"].map { PlayerProfile(name: $0) }

    @Test(arguments: 1...5)
    func playerCountLimits(count: Int) {
        let result = Result { try DartsMatch(players: Array(players.prefix(count)), seed: 1) }
        if (1...4).contains(count) {
            #expect((try? result.get()) != nil)
        }
        let five = players + [PlayerProfile(name: "Piąty")]
        #expect(throws: DartsMatch.MatchError.playerCount(5)) { try DartsMatch(players: five, seed: 1) }
        #expect(throws: DartsMatch.MatchError.duplicatePlayers) { try DartsMatch(players: [players[0], players[0]], seed: 1) }
    }

    @Test func fourPlayersRotate() throws {
        var match = try DartsMatch(players: players, seed: 1)
        var order: [String] = []
        for _ in 0..<5 {
            order.append(match.currentPlayer.name)
            for _ in 0..<3 { match.record(hit: .single(1)) }
        }
        #expect(order == ["Ola", "Bartek", "Michał", "Ania", "Ola"])
        #expect(match.state.turn.round == 2)
        #expect(match.previousTurnLandings.count == 3)
        #expect(match.landings.isEmpty)
    }

    @Test func undoAcrossTurnBoundaryAndWin() throws {
        var match = try DartsMatch(players: Array(players.prefix(2)), rules: X01Rules(startScore: 40), seed: 1)
        match.record(hit: .single(1))
        match.record(hit: .single(1))
        match.record(hit: .single(1))
        #expect(match.currentPlayer.name == "Bartek")
        match.undo()
        #expect(match.currentPlayer.name == "Ola")
        #expect(match.landings.count == 2)
        #expect(match.remaining(for: players[0]) == 38)

        match.record(hit: .double(19))
        #expect(match.winner?.name == "Ola")
        #expect(match.isFinished)
        match.undo()
        #expect(!match.isFinished)
        #expect(match.remaining(for: players[0]) == 38)
    }

    @Test func checkoutHintFollowsDartsLeft() throws {
        var match = try DartsMatch(players: Array(players.prefix(2)), rules: X01Rules(startScore: 100), seed: 1)
        #expect(match.checkoutHint == [.triple(20), .double(20)])
        match.record(hit: .single(20))
        #expect(match.checkoutHint == [.double(20), .double(20)] || match.checkoutHint?.count == 2)
    }

    @Test func matchStateRoundTripsThroughJSON() throws {
        var match = try DartsMatch(players: Array(players.prefix(3)), seed: 3)
        match.throwDart(aimingAt: BoardPoint(x: 0, y: 103))
        match.record(hit: .triple(19))
        let data = try JSONEncoder().encode(match)
        let decoded = try JSONDecoder().decode(DartsMatch.self, from: data)
        #expect(decoded == match)
    }
}

/// Od ruchu ręki do wyniku: syntetyczne próbki → FlickThrowRecognizer → kalibracja → tarcza → 501.
@Suite("Od ruchu do wyniku")
struct EndToEndTests {
    private func throwEvent(seed: UInt64, yaw: Double = 0, pitch: Double = 0, wrist: WristSide = .right) throws -> ThrowEvent {
        var motion = SyntheticMotion(orientation: WristOrientation(wrist: wrist), seed: seed)
        motion.hold(1)
        motion.flick(.init(peakRate: 12 + Double(seed % 3) * 0.3, yawDeviation: yaw, pitchDeviation: pitch))
        motion.hold(1)
        var recognizer = FlickThrowRecognizer(orientation: WristOrientation(wrist: wrist))
        let events = MotionReplayer(recording: motion.recording(label: "e2e")).events(&recognizer)
        return try #require(events.first)
    }

    @Test func calibratedThrowsLandAroundBull() throws {
        var session = CalibrationSession()
        var calibration: Calibration?
        for seed in UInt64(1)...3 {
            if case .done(let result) = session.add(try throwEvent(seed: seed)) { calibration = result }
        }
        let player = PlayerProfile(name: "Ola", difficulty: .easy, calibrations: [.flick: try #require(calibration)])
        var match = try DartsMatch(players: [player], seed: 11)
        var radii: [Double] = []
        for seed in UInt64(10)..<16 {
            let (landing, _) = match.throwDart(try throwEvent(seed: seed))
            radii.append(landing.aim.radius)
        }
        // Po kalibracji punkt celowania jest blisko środka. Rozrzut ~2–3 cm bierze się
        // z różnej siły rzutów (seed % 3): mocniejszy rzut ma w szczycie ręką niżej.
        #expect(radii.allSatisfy { $0 < 40 })
        #expect(radii.reduce(0, +) / Double(radii.count) < 20)
        #expect(match.state.dartsThrown[0] == 6)
    }

    @Test func aimingRightAndUpMovesDarts() throws {
        let model = DartThrowModel()
        let center = try #require(model.aimPoint(for: try throwEvent(seed: 1), calibration: .none))
        let right = try #require(model.aimPoint(for: try throwEvent(seed: 1, yaw: 0.1), calibration: .none))
        let up = try #require(model.aimPoint(for: try throwEvent(seed: 1, pitch: 0.1), calibration: .none))
        #expect(right.x - center.x > 80)
        #expect(up.y - center.y > 80)
    }

    @Test func leftHandedPlayerAimsTheSameWay() throws {
        let model = DartThrowModel()
        let rightHand = try #require(model.aimPoint(for: try throwEvent(seed: 4, yaw: 0.1), calibration: .none))
        let leftHand = try #require(model.aimPoint(for: try throwEvent(seed: 4, yaw: 0.1, wrist: .left), calibration: .none))
        #expect(abs(rightHand.x - leftHand.x) < 10)
        #expect(abs(rightHand.y - leftHand.y) < 10)
    }
}
