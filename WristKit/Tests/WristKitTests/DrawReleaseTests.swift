import Foundation
import Testing
@testable import WristKit

/// Nagranie łucznika: ręka opuszczona → uniesienie → (budowa) → spoczynek.
private func record(
    wrist: WristSide = .right,
    seed: UInt64 = 1,
    _ build: (inout SyntheticMotion) -> Void
) -> [DrawEvent] {
    var motion = SyntheticMotion(orientation: WristOrientation(wrist: wrist), heading: Double(seed) * 0.7, elevation: -1.2, seed: seed)
    motion.hold(0.5)
    motion.raiseArm()
    motion.hold(0.4)
    build(&motion)
    motion.hold(1)
    var recognizer = DrawReleaseRecognizer(orientation: WristOrientation(wrist: wrist))
    return MotionReplayer(recording: motion.recording(label: "draw")).events(&recognizer)
}

private func releases(_ events: [DrawEvent]) -> [ShotRelease] {
    events.compactMap { if case .released(let shot) = $0 { shot } else { nil } }
}

private func cancels(_ events: [DrawEvent]) -> Int {
    events.filter { $0 == .cancelled }.count
}

/// Pełny strzał: naciąg, kotwica, puszczenie.
private func shot(_ motion: inout SyntheticMotion, draw: Double = 0.3, hold: TimeInterval = 2.5, tremor: Double = 0.02) {
    motion.draw(peakAcceleration: draw)
    motion.anchor(0.4, tremor: 0.02)
    motion.anchor(hold - 0.4, tremor: tremor)
    motion.release()
}

@Suite("Łuk: naciąg i puszczenie")
struct DrawReleaseTests {
    @Test(arguments: UInt64(1)...10)
    func goodShot(seed: UInt64) throws {
        let events = record(seed: seed) { shot(&$0) }
        let release = try #require(releases(events).first)
        #expect(releases(events).count == 1)
        #expect(release.strength > 0.9)
        #expect(abs(release.holdTime - 2.5) < 0.4)
        #expect(release.stability < 0.15)
        #expect(events.contains { if case .drawStarted = $0 { true } else { false } })
        #expect(cancels(events) == 0)
    }

    @Test func weakDrawGivesWeakShot() throws {
        let strong = try #require(releases(record { shot(&$0) }).first)
        let weak = try #require(releases(record { shot(&$0, draw: 0.13) }).first)
        #expect(weak.strength < 0.6)
        #expect(weak.strength < strong.strength)
    }

    @Test func tooLittleDrawIsNoShot() {
        let events = record { shot(&$0, draw: 0.04) }
        #expect(releases(events).isEmpty)
    }

    @Test func loweringTheArmCancels() {
        let events = record { motion in
            motion.draw()
            motion.anchor(1)
            motion.lowerArm(angle: 1.3)
        }
        #expect(releases(events).isEmpty)
        #expect(cancels(events) == 1)
    }

    @Test func shakyAnchorHasWorseStability() throws {
        let steady = try #require(releases(record { shot(&$0) }).first)
        let shaky = try #require(releases(record { shot(&$0, tremor: 0.3) }).first)
        #expect(shaky.stability > steady.stability * 3)
    }

    @Test func jerkWithoutDrawIsNoShot() {
        let events = record { motion in
            motion.hold(1)
            motion.release()
        }
        #expect(releases(events).isEmpty)
    }

    @Test func releaseRightAfterDrawWithoutAnchorIsNoShot() {
        let events = record { motion in
            motion.draw()
            motion.release()
        }
        #expect(releases(events).isEmpty)
    }

    @Test func longHoldIsMeasured() throws {
        let release = try #require(releases(record { shot(&$0, hold: 6) }).first)
        #expect(abs(release.holdTime - 6) < 0.4)
    }

    @Test func leftHandWorksTheSame() throws {
        let release = try #require(releases(record(wrist: .left) { shot(&$0) }).first)
        #expect(release.strength > 0.9)
    }

    @Test func twoShotsInARow() {
        let events = record { motion in
            shot(&motion)
            motion.hold(1)
            shot(&motion, draw: 0.2)
        }
        let shots = releases(events)
        #expect(shots.count == 2)
        #expect(cancels(events) == 0)
    }

    @Test func hangingArmIgnoresMotion() {
        var motion = SyntheticMotion(elevation: -1.2, seed: 3)
        motion.hold(0.5)
        motion.wave()
        motion.draw()
        motion.release()
        motion.hold(1)
        var recognizer = DrawReleaseRecognizer()
        #expect(MotionReplayer(recording: motion.recording(label: "x")).events(&recognizer).isEmpty)
    }

    @Test func liveHoldingAbout20Hz() {
        let events = record { shot(&$0, hold: 2) }
        let holding = events.filter { if case .holding = $0 { true } else { false } }
        #expect(holding.count >= 30 && holding.count <= 45)
    }
}
