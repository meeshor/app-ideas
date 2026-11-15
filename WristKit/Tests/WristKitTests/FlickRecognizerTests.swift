import Foundation
import Testing
@testable import WristKit

@Suite("Rzut z nadgarstka: nagrania")
struct FlickFixtureTests {
    @Test func syntheticSetHasAtLeastTenCases() {
        #expect(SyntheticFixtures.cases.count >= 10)
        for item in SyntheticFixtures.cases {
            #expect(FixtureExpectation(label: item.label) != nil, "brak reguły dla \(item.label)")
        }
    }

    @Test func syntheticRecordingsMatchExpectations() {
        let results = SyntheticFixtures.all.map { recording in
            FixtureResult(
                label: recording.metadata.label,
                expectation: FixtureExpectation(label: recording.metadata.label) ?? .count(-1),
                events: MotionReplayer(recording: recording).flickEvents()
            )
        }
        let failures = FixtureJudge.failures(in: results)
        #expect(failures.isEmpty, "\(failures.joined(separator: "\n"))")
    }

    /// Prawdziwe nagrania z Fixtures/real (jeśli są). Bez plików test przechodzi.
    @Test func realRecordingsMatchExpectations() throws {
        let recordings = try Self.realRecordings()
        guard !recordings.isEmpty else { return }
        var results: [FixtureResult] = []
        for recording in recordings {
            guard let expectation = FixtureExpectation(label: recording.metadata.label) else {
                print("Pomijam nagranie o nieznanej etykiecie: \(recording.metadata.label)")
                continue
            }
            results.append(FixtureResult(
                label: recording.metadata.label,
                expectation: expectation,
                events: MotionReplayer(recording: recording).flickEvents()
            ))
        }
        let failures = FixtureJudge.failures(in: results)
        #expect(failures.isEmpty, "\(failures.joined(separator: "\n"))")
    }

    static func realRecordings() throws -> [MotionRecording] {
        guard let directory = Bundle.module.url(forResource: "Fixtures/real", withExtension: nil) else { return [] }
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == MotionRecording.fileExtension }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        return try files.map { url in
            var recording = try MotionRecording.decode(from: Data(contentsOf: url))
            // Etykieta z nazwy pliku ma pierwszeństwo (łatwo poprawić po eksporcie).
            recording.metadata.label = url.deletingPathExtension().lastPathComponent
            return recording
        }
    }

    @Test func directionDeviationsAreRecovered() throws {
        func event(_ spec: SyntheticMotion.Flick, heading: Double = 0, wrist: WristSide = .right) throws -> ThrowEvent {
            var motion = SyntheticMotion(orientation: WristOrientation(wrist: wrist), heading: heading, roll: heading * 0.4, seed: 1)
            motion.tremor = 0
            motion.accelerationNoise = 0
            motion.hold(1)
            motion.flick(spec)
            motion.hold(1)
            let events = MotionReplayer(recording: motion.recording(label: "x")).flickEvents()
            return try #require(events.first)
        }
        for heading in [0.0, 2.0] {
            for wrist in WristSide.allCases {
                let center = try event(.init(), heading: heading, wrist: wrist)
                let right = try event(.init(yawDeviation: 0.2), heading: heading, wrist: wrist)
                let high = try event(.init(pitchDeviation: 0.15), heading: heading, wrist: wrist)
                // Tolerancja ~20%: próbka szczytu ma orientację sprzed swojego kroku całkowania,
                // więc generator dochodzi do ~89% zadanego odchylenia (suma dyskretna sin²).
                #expect(abs(center.yaw) < 0.01)
                #expect(abs((right.yaw - center.yaw) - 0.2) < 0.04)
                #expect(abs((high.pitch - center.pitch) - 0.15) < 0.03)
                #expect(abs(high.yaw - center.yaw) < 0.02)
            }
        }
    }
}

@Suite("Rzut z nadgarstka: maszyna stanów")
struct FlickStateMachineTests {
    private func run(_ build: (inout SyntheticMotion) -> Void, tuning: FlickTuning = FlickTuning()) -> [GestureOutput<ThrowEvent>] {
        var motion = SyntheticMotion(seed: 42)
        motion.hold(1)
        build(&motion)
        motion.hold(1.5)
        var recognizer = FlickThrowRecognizer(tuning: tuning)
        return MotionReplayer(recording: motion.recording(label: "x")).run(&recognizer)
    }

    @Test func phasesOfASingleThrow() {
        let phases = run { $0.flick(.init()) }.compactMap { output -> GesturePhase? in
            if case .phaseChanged(let phase) = output { return phase }
            return nil
        }
        #expect(phases == [.ready, .active, .cooldown, .idle, .ready])
    }

    @Test func eventWaitsForConfirmWindow() throws {
        var motion = SyntheticMotion(seed: 7)
        motion.hold(1)
        motion.flick(.init())
        motion.hold(1)
        var recognizer = FlickThrowRecognizer()
        var eventAt: TimeInterval?
        var event: ThrowEvent?
        for sample in motion.samples {
            for output in recognizer.process(sample) {
                if case .event(let e) = output {
                    eventAt = sample.t
                    event = e
                }
            }
        }
        let emitted = try #require(eventAt)
        let thrown = try #require(event)
        let delay = emitted - thrown.watchTimestamp
        #expect(delay >= FlickTuning().confirmWindow)
        #expect(delay < FlickTuning().confirmWindow + 0.15)
        #expect(thrown.kind == .flick)
        #expect(thrown.speed > 3 && thrown.speed < 6)
    }

    @Test func secondThrowDuringCooldownIsIgnored() {
        let outputs = run { motion in
            motion.flick(.init(backswing: false))
            // Po potwierdzeniu pierwszego rzutu, ale w trakcie cooldown.
            motion.hold(0.3)
            motion.flick(.init(backswing: false))
        }
        let events = outputs.filter { if case .event = $0 { true } else { false } }
        #expect(events.count == 1)
    }

    @Test func noThrowWithoutStillnessFirst() {
        var motion = SyntheticMotion(seed: 3)
        motion.flick(.init(backswing: false))
        motion.hold(0.1)
        var recognizer = FlickThrowRecognizer()
        #expect(MotionReplayer(recording: motion.recording(label: "x")).events(&recognizer).isEmpty)
    }

    @Test func minReadyElevationRejectsHangingArm() {
        var tuning = FlickTuning()
        tuning.minReadyElevation = -0.5
        func count(elevation: Double) -> Int {
            var motion = SyntheticMotion(elevation: elevation, seed: 5)
            motion.hold(1)
            motion.flick(.init())
            motion.hold(1)
            var recognizer = FlickThrowRecognizer(tuning: tuning)
            return MotionReplayer(recording: motion.recording(label: "x")).events(&recognizer).count
        }
        #expect(count(elevation: 0.9) == 1)
        #expect(count(elevation: -1.3) == 0)
    }

    @Test func resetClearsState() {
        var motion = SyntheticMotion(seed: 9)
        motion.hold(1)
        var recognizer = FlickThrowRecognizer()
        for sample in motion.samples { _ = recognizer.process(sample) }
        #expect(recognizer.phase == .ready)
        recognizer.reset()
        #expect(recognizer.phase == .idle)
    }
}

@Suite("Geometria i kalibracja")
struct GeometryCalibrationTests {
    @Test func handAxisFollowsWristAndCrown() {
        #expect(WristOrientation(wrist: .left).handAxis == Vector3(1, 0, 0))
        #expect(WristOrientation(wrist: .right).handAxis == Vector3(-1, 0, 0))
        #expect(WristOrientation(wrist: .left, crownTowardHand: false).handAxis == Vector3(-1, 0, 0))
        #expect(WristOrientation(wrist: .right, crownTowardHand: false).handAxis == Vector3(1, 0, 0))
    }

    @Test(arguments: WristSide.allCases)
    func syntheticPoseHasRequestedElevation(wrist: WristSide) {
        let orientation = WristOrientation(wrist: wrist)
        let motion = SyntheticMotion(orientation: orientation, heading: 0.7, elevation: 0.5, roll: 0.3)
        let gravity = motion.attitude.inverse.act(on: Vector3(0, 0, -1))
        #expect(abs(ThrowGeometry.elevation(of: orientation.handAxis, gravity: gravity) - 0.5) < 1e-9)
        #expect(abs(motion.handDirection.z - sin(0.5)) < 1e-9)
    }

    @Test func yawIsZeroForPureElevationChange() {
        let o = WristOrientation()
        let a = SyntheticMotion.pose(heading: 0.3, elevation: 0.8, roll: 0, orientation: o)
        let b = SyntheticMotion.pose(heading: 0.3, elevation: -0.2, roll: 0, orientation: o)
        let gravity = a.inverse.act(on: Vector3(0, 0, -1))
        #expect(abs(ThrowGeometry.yaw(axis: o.handAxis, readyAttitude: a, readyGravity: gravity, attitude: b)) < 1e-9)
        let c = SyntheticMotion.pose(heading: 0.3 - 0.25, elevation: 0.8, roll: 0, orientation: o)
        let yaw = ThrowGeometry.yaw(axis: o.handAxis, readyAttitude: a, readyGravity: gravity, attitude: c)
        #expect(abs(yaw - 0.25) < 1e-9, "obrót w prawo (heading maleje) = dodatni yaw")
    }

    @Test func calibrationSessionCollectsThrows() {
        var session = CalibrationSession(requiredThrows: 3, maxSpread: 0.2)
        #expect(session.add(yaw: 0.1, pitch: -0.3) == .needMore(remaining: 2))
        #expect(session.add(yaw: 0.12, pitch: -0.25) == .needMore(remaining: 1))
        guard case .done(let calibration) = session.add(yaw: 0.08, pitch: -0.35) else {
            Issue.record("brak kalibracji")
            return
        }
        #expect(abs(calibration.yawOffset - 0.1) < 1e-9)
        #expect(abs(calibration.pitchOffset + 0.3) < 1e-9)
        #expect(calibration.sampleCount == 3)
    }

    @Test func calibrationSessionRejectsScatteredSeries() {
        var session = CalibrationSession(requiredThrows: 2, maxSpread: 0.1)
        _ = session.add(yaw: 0, pitch: 0)
        guard case .inconsistent = session.add(yaw: 0.5, pitch: 0) else {
            Issue.record("seria powinna być odrzucona")
            return
        }
        #expect(session.remaining == 2)
    }

    @Test func seededRandomIsDeterministic() {
        var a = SeededRandom(seed: 99)
        var b = SeededRandom(seed: 99)
        #expect((0..<5).map { _ in a.next() } == (0..<5).map { _ in b.next() })
        var c = SeededRandom(seed: 1)
        let values = (0..<2000).map { _ in c.nextGaussian() }
        let mean = values.reduce(0, +) / Double(values.count)
        #expect(abs(mean) < 0.1)
    }
}
