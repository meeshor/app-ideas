import Foundation
import Testing
@testable import WristKit

@Suite("Podgląd na żywo i opóźnienia")
struct StreamingTests {
    @Test func ringBufferKeepsNewest() {
        var buffer = RingBuffer<Int>(capacity: 3)
        #expect(buffer.isEmpty)
        #expect(buffer.last == nil)
        buffer.append(contentsOf: [1, 2])
        #expect(buffer.elements == [1, 2])
        buffer.append(contentsOf: [3, 4, 5])
        #expect(buffer.elements == [3, 4, 5])
        #expect(buffer.last == 5)
        buffer.append(6)
        #expect(buffer.elements == [4, 5, 6])
        #expect(buffer.count == 3)
        buffer.removeAll()
        #expect(buffer.isEmpty)
    }

    @Test func batcherDecimatesAndBatches() {
        var batcher = SampleBatcher(decimation: 4, maxBatchSize: 5, maxInterval: 10)
        var batches: [[MotionSample]] = []
        for i in 0..<40 {
            if let batch = batcher.add(MotionSample(t: Double(i) / 100)) {
                batches.append(batch)
            }
        }
        #expect(batches.count == 2)
        #expect(batches.allSatisfy { $0.count == 5 })
        #expect(batches[1].first?.t == 0.2)
        let rest = batcher.flush()
        #expect(rest == nil)
    }

    @Test func batcherFlushesOnInterval() {
        var batcher = SampleBatcher(decimation: 1, maxBatchSize: 100, maxInterval: 0.05)
        var first: [MotionSample]?
        for i in 0..<20 where first == nil {
            first = batcher.add(MotionSample(t: Double(i) / 100))
        }
        let count = first?.count ?? 0
        #expect((5...7).contains(count))
    }

    @Test func latencySummaryPercentiles() throws {
        let summary = try #require(LatencySummary(values: (1...10).map(Double.init)))
        #expect(summary.count == 10)
        #expect(summary.min == 1)
        #expect(summary.max == 10)
        #expect(abs(summary.median - 5.5) < 1e-9)
        #expect(abs(summary.p90 - 9.1) < 1e-9)
        #expect(LatencySummary(values: []) == nil)
        let row = try #require(LatencySummary(values: [0.05, 0.1])).markdownRow(name: "RTT")
        #expect(row == "| RTT | 2 | 50 | 75 | 95 | 100 |")
    }

    @Test func eulerAnglesPerAxis() {
        let roll = Quaternion(axis: Vector3(1, 0, 0), angle: 0.2).eulerAngles
        let pitch = Quaternion(axis: Vector3(0, 1, 0), angle: 0.1).eulerAngles
        let yaw = Quaternion(axis: Vector3(0, 0, 1), angle: 0.3).eulerAngles
        #expect(abs(roll.roll - 0.2) < 1e-9 && abs(roll.pitch) < 1e-9 && abs(roll.yaw) < 1e-9)
        #expect(abs(pitch.pitch - 0.1) < 1e-9 && abs(pitch.roll) < 1e-9)
        #expect(abs(yaw.yaw - 0.3) < 1e-9 && abs(yaw.pitch) < 1e-9)
    }

    @Test func newPayloadsRoundTrip() throws {
        let payloads: [WristPayload] = [
            .samples([MotionSample(t: 1), MotionSample(t: 1.04)]),
            .status(WatchStatus(isRecording: true, recordingDuration: 2.5, sampleCount: 250, lastError: "x")),
            .control(.startLiveStream(sampleRate: 25)),
            .control(.stopLiveStream),
            .control(.requestStatus)
        ]
        for payload in payloads {
            let message = WristMessage(seq: 1, sentAt: 0, payload: payload)
            #expect(try WristMessage.decode(from: message.encoded()) == message)
        }
    }
}

@Suite("Magazyn nagrań")
struct RecordingStoreTests {
    private func makeStore() throws -> RecordingStore {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("wristkit-tests-\(UUID().uuidString)", isDirectory: true)
        return try RecordingStore(directory: dir)
    }

    private func recording(label: String) -> MotionRecording {
        MotionRecording(
            metadata: .init(createdAt: Date(timeIntervalSince1970: 1_700_000_000), label: label),
            samples: [MotionSample(t: 0), MotionSample(t: 0.01)]
        )
    }

    @Test func fileNameIsSanitized() {
        #expect(recording(label: "Flick środek 01!").suggestedFileName == "Flick_środek_01_20231114-221320.wkrec")
        #expect(recording(label: "??").suggestedFileName == "nagranie_20231114-221320.wkrec")
    }

    @Test func saveListLoadDelete() throws {
        let store = try makeStore()
        defer { try? FileManager.default.removeItem(at: store.directory) }

        let first = try store.save(recording(label: "a"))
        let second = try store.save(recording(label: "a"))
        #expect(first != second)
        #expect(second.lastPathComponent == "a_20231114-221320-2.wkrec")

        let entries = try store.list()
        #expect(entries.count == 2)
        let loaded = try store.load(first)
        #expect(loaded.metadata.label == "a")
        #expect(loaded.samples == recording(label: "a").samples)

        try store.delete(first)
        #expect(try store.list().count == 1)
    }

    @Test func importMovesFile() throws {
        let store = try makeStore()
        defer { try? FileManager.default.removeItem(at: store.directory) }
        let source = FileManager.default.temporaryDirectory.appendingPathComponent("in-\(UUID().uuidString).wkrec")
        try recording(label: "b").encoded().write(to: source)

        let imported = try store.importFile(at: source, preferredName: "b_watch.wkrec")
        #expect(imported.lastPathComponent == "b_watch.wkrec")
        #expect(!FileManager.default.fileExists(atPath: source.path))
        #expect(try store.list().map(\.name) == ["b_watch"])
    }
}
