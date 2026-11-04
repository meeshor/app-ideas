import Foundation
import Testing
@testable import WristKit

@Suite("Transport i profile")
struct MessageTests {
    @Test func throwEventRoundTrip() throws {
        let event = ThrowEvent(
            kind: .flick, speed: 6.5, pitch: 0.1, yaw: -0.05,
            spin: 1.2, jerk: 0.4, watchTimestamp: 1234.5
        )
        let message = WristMessage(seq: 7, sentAt: 1234.6, payload: .throwEvent(event))
        let decoded = try WristMessage.decode(from: message.encoded())
        #expect(decoded == message)
    }

    @Test func allPayloadsRoundTrip() throws {
        let payloads: [WristPayload] = [
            .live(LiveGestureState(phase: .windup, intensity: 0.5, t: 1)),
            .phase(.ready),
            .ping(id: 1, sentAt: 10),
            .pong(id: 1, pingSentAt: 10, receivedAt: 20, repliedAt: 20.001),
            .control(.startSession(kind: .flick)),
            .control(.setActivePlayer(name: "Ola", wrist: .left)),
            .control(.updateTuning(.default))
        ]
        for (i, payload) in payloads.enumerated() {
            let message = WristMessage(seq: UInt64(i), sentAt: 0, payload: payload)
            #expect(try WristMessage.decode(from: message.encoded()) == message)
        }
    }

    @Test func clockSyncPicksShortestRoundTrip() {
        var sync = ClockSync()
        // Zegar B wyprzedza A o 100 s; drugi pomiar ma długą kolejkę w jedną stronę.
        sync.add(ClockSyncSample(t0: 0, t1: 100.02, t2: 100.02, t3: 0.04))
        sync.add(ClockSyncSample(t0: 1, t1: 101.30, t2: 101.30, t3: 1.32))
        #expect(abs(sync.best!.roundTrip - 0.04) < 1e-9)
        #expect(abs(sync.offset! - 100) < 1e-9)
        #expect(abs(sync.toLocal(remote: 150)! - 50) < 1e-9)
        #expect(sync.medianRoundTrip != nil)
    }

    @Test func calibrationAveragesCenterThrows() {
        let calibration = Calibration(centerThrows: [(0.1, -0.02), (0.2, 0.0), (0.0, 0.02)])
        #expect(calibration.sampleCount == 3)
        #expect(abs(calibration.yawOffset - 0.1) < 1e-9)
        let corrected = calibration.apply(yaw: 0.1, pitch: 0)
        #expect(abs(corrected.yaw) < 1e-9)
        #expect(Calibration(centerThrows: []) == .none)
    }

    @Test func profileRoundTripWithCalibrations() throws {
        let profile = PlayerProfile(
            name: "Michał", wrist: .left, difficulty: .hard,
            calibrations: [.flick: Calibration(yawOffset: 0.05, pitchOffset: 0, sampleCount: 3)]
        )
        let data = try JSONEncoder().encode(profile)
        #expect(try JSONDecoder().decode(PlayerProfile.self, from: data) == profile)
        #expect(profile.calibration(for: .overarm) == .none)
        #expect(WristSide.left.mirrorSign == -1)
    }
}
