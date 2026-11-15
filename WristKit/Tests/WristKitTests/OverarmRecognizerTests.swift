import Foundation
import Testing
@testable import WristKit

/// Wynik nagrania: kolejność zdarzeń jako litery (F = zwód, T = rzut).
private func run(
    wrist: WristSide = .right,
    heading: Double = 0,
    seed: UInt64 = 1,
    _ build: (inout SyntheticMotion) -> Void
) -> [ThrowEvent] {
    var motion = SyntheticMotion(orientation: WristOrientation(wrist: wrist), heading: heading, elevation: 0.8, seed: seed)
    motion.hold(1)
    build(&motion)
    motion.hold(1.5)
    var recognizer = OverarmThrowRecognizer(orientation: WristOrientation(wrist: wrist))
    return MotionReplayer(recording: motion.recording(label: "overarm")).events(&recognizer)
}

private func pattern(_ events: [ThrowEvent]) -> String {
    events.map { $0.isFeint ? "F" : "T" }.joined()
}

@Suite("Rzut nad głową (ręczna)")
struct OverarmRecognizerTests {
    @Test(arguments: UInt64(1)...20)
    func singleThrow(seed: UInt64) {
        let events = run(heading: Double(seed) * 0.3, seed: seed) { $0.overarm(.init()) }
        #expect(pattern(events) == "T")
        #expect(events.first?.kind == .overarm)
        #expect((events.first?.speed ?? 0) > 8)
    }

    @Test(arguments: UInt64(1)...20)
    func feintThenThrow(seed: UInt64) {
        let events = run(seed: seed) { motion in
            motion.feint()
            motion.hold(0.4)
            motion.overarm(.init())
        }
        #expect(pattern(events) == "FT")
    }

    @Test func doubleFeintThenThrow() {
        let events = run { motion in
            motion.feint()
            motion.hold(0.3)
            motion.feint(forwardRate: 6)
            motion.hold(0.3)
            motion.overarm(.init(peakRate: 20))
        }
        #expect(pattern(events) == "FFT")
    }

    @Test func directionsAndSpin() throws {
        let center = try #require(run { $0.overarm(.init()) }.first)
        let right = try #require(run { $0.overarm(.init(yawDeviation: 0.2)) }.first)
        let left = try #require(run { $0.overarm(.init(yawDeviation: -0.2)) }.first)
        let high = try #require(run { $0.overarm(.init(pitchDeviation: 0.15)) }.first)
        let spin = try #require(run { $0.overarm(.init(spinRate: 8)) }.first)
        #expect(right.yaw - center.yaw > 0.12)
        #expect(center.yaw - left.yaw > 0.12)
        #expect(high.pitch - center.pitch > 0.08)
        #expect(spin.spin > 3)
    }

    @Test func leftHandMirrorsSpinNotDirection() throws {
        let right = try #require(run(wrist: .right) { $0.overarm(.init(yawDeviation: 0.2, spinRate: 8)) }.first)
        let left = try #require(run(wrist: .left) { $0.overarm(.init(yawDeviation: 0.2, spinRate: 8)) }.first)
        // Skręt w trakcie zamachu lekko zbacza tor (±0,03 rad), lustrzanie dla lewej ręki: to fizyka, nie błąd.
        #expect(abs(right.yaw - left.yaw) < 0.08)
        #expect(abs(right.spin - left.spin) < 1)
    }

    @Test func weakThrowIsNotAThrow() {
        let events = run { $0.overarm(.init(peakRate: 6)) }
        #expect(!events.contains { !$0.isFeint })
    }

    @Test func noiseGivesNoThrows() {
        for build: (inout SyntheticMotion) -> Void in [
            { $0.lowerArm() },
            { $0.hold(4) },
            { $0.wave() },
            { $0.scratch() }
        ] {
            let events = run(build)
            #expect(!events.contains { !$0.isFeint }, "\(pattern(events))")
        }
    }

    @Test func phasesOfThrow() {
        var motion = SyntheticMotion(elevation: 0.8, seed: 3)
        motion.hold(1)
        motion.overarm(.init())
        motion.hold(1.5)
        var recognizer = OverarmThrowRecognizer()
        let phases = MotionReplayer(recording: motion.recording(label: "x")).run(&recognizer).compactMap { output -> GesturePhase? in
            if case .phaseChanged(let phase) = output { return phase }
            return nil
        }
        #expect(phases == [.ready, .windup, .active, .cooldown, .idle, .ready])
    }
}
