import Foundation
import Testing
@testable import WristKit

/// Recognizer testowy: zdarzenie, gdy |przyspieszenie| przekroczy próg.
private struct ThresholdRecognizer: GestureRecognizer {
    var threshold: Double
    var phase: GesturePhase = .idle

    mutating func process(_ sample: MotionSample) -> [GestureOutput<Double>] {
        let magnitude = sample.userAcceleration.length
        if magnitude > threshold, phase == .idle {
            phase = .cooldown
            return [.phaseChanged(.cooldown), .event(sample.t)]
        }
        if magnitude <= threshold, phase == .cooldown {
            phase = .idle
            return [.phaseChanged(.idle)]
        }
        return []
    }

    mutating func reset() { phase = .idle }
}

private func makeRecording(spikesAt spikes: Set<Int>, count: Int = 100) -> MotionRecording {
    let samples = (0..<count).map { i in
        MotionSample(
            t: Double(i) / 100,
            userAcceleration: spikes.contains(i) ? Vector3(2, 0, 0) : .zero
        )
    }
    return MotionRecording(
        metadata: .init(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            label: "synthetic_spikes"
        ),
        samples: samples
    )
}

@Suite("Nagrania")
struct RecordingTests {
    @Test func sampleEncodesAsFlatArray() throws {
        let sample = MotionSample(
            t: 1.5,
            attitude: Quaternion(x: 0, y: 0, z: 0.5, w: 0.75),
            rotationRate: Vector3(0.25, -0.5, 1),
            userAcceleration: Vector3(0.125, 0, -2),
            gravity: Vector3(0, -1, 0)
        )
        let data = try JSONEncoder().encode(sample)
        let array = try JSONDecoder().decode([Double].self, from: data)
        #expect(array.count == 14)
        #expect(array.first == 1.5)
        #expect(try JSONDecoder().decode(MotionSample.self, from: data) == sample)
    }

    @Test func recordingRoundTrip() throws {
        let recording = makeRecording(spikesAt: [10, 50])
        let decoded = try MotionRecording.decode(from: recording.encoded())
        #expect(decoded == recording)
        #expect(abs(decoded.duration - 0.99) < 1e-9)
    }

    @Test func rejectsFutureFormat() throws {
        var recording = makeRecording(spikesAt: [])
        recording.formatVersion = 99
        let data = try recording.encoded()
        #expect(throws: MotionRecording.FormatError.unsupportedVersion(99)) {
            try MotionRecording.decode(from: data)
        }
    }

    @Test func recorderRespectsLimitAndOrder() {
        var recorder = MotionRecorder(maxDuration: 0.05)
        for i in 0..<10 {
            recorder.append(MotionSample(t: Double(i) / 100))
        }
        #expect(recorder.samples.count == 6) // 0.00 … 0.05
        #expect(recorder.isFull)
        #expect(!recorder.append(MotionSample(t: 0)))

        let recording = recorder.finish(metadata: .init(label: "limit"))
        #expect(recording.samples.count == 6)
        #expect(recorder.samples.isEmpty)
    }

    @Test func replayerFeedsRecognizer() {
        let replayer = MotionReplayer(recording: makeRecording(spikesAt: [10, 11, 50]))
        var recognizer = ThresholdRecognizer(threshold: 1)
        let events = replayer.events(&recognizer)
        #expect(events == [0.10, 0.50])
    }

    @Test func replayerStreamsAllSamples() async {
        let recording = makeRecording(spikesAt: [], count: 20)
        var received = 0
        for await _ in MotionReplayer(recording: recording).stream(rate: 50) {
            received += 1
        }
        #expect(received == 20)
    }

    @Test func stillnessNeedsDuration() {
        var detector = StillnessDetector()
        var readyAt: Double?
        for i in 0..<60 {
            let t = Double(i) / 100
            // Ruch do 0.10 s, potem spoczynek.
            let sample = MotionSample(t: t, rotationRate: i < 10 ? Vector3(3, 0, 0) : .zero)
            if detector.process(sample), readyAt == nil { readyAt = t }
        }
        // Spoczynek od 0.10 s + 0.25 s progu (tolerancja jednej próbki na zaokrąglenia).
        let ready = readyAt ?? -1
        #expect(ready >= 0.349 && ready <= 0.361)
    }
}
