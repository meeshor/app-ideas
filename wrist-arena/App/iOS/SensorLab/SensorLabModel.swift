import Foundation
import Observation
import UIKit
import WristKit
import WristKitDevice

/// Laboratorium czujników (M1): podgląd ruchu z zegarka, nagrania, pomiar opóźnienia.
@MainActor
@Observable
final class SensorLabModel {
    private(set) var isReachable = false
    private(set) var isPaired = false
    private(set) var isWatchAppInstalled = false
    private(set) var watchStatus: WatchStatus?

    /// Ostatnie ~10 s podglądu (25 Hz).
    private(set) var live = RingBuffer<MotionSample>(capacity: 250)
    private(set) var isStreaming = false

    private(set) var clockSync = ClockSync(capacity: 64)
    /// Opóźnienie transportu jednej wiadomości (wysłanie na zegarku → odbiór na telefonie).
    private(set) var transportLatencies = RingBuffer<Double>(capacity: 500)
    /// Wiek najnowszej próbki w paczce przy odbiorze (transport + czekanie na skompletowanie paczki).
    private(set) var sampleAges = RingBuffer<Double>(capacity: 500)
    private(set) var receivedMessages = 0
    private(set) var lostMessages = 0
    private(set) var isMeasuring = false

    private(set) var recordings: [RecordingStore.Entry] = []
    var recordingLabel = "flick_center_01"
    var errorMessage: String?

    private let link = WatchLink.shared
    private let store = try? RecordingStore(directory: RecordingStore.defaultDirectory())
    private var lastSeq: UInt64?
    private var nextPingID: UInt32 = 0
    private var activated = false

    func activate() {
        guard !activated else { return }
        activated = true
        link.onMessage = { [weak self] message, receivedAt in
            self?.handle(message, receivedAt: receivedAt)
        }
        link.onFile = { [weak self] url, name in
            self?.importFile(url, name: name)
        }
        link.onStateChange = { [weak self] in
            self?.refreshLinkState()
        }
        link.activate()
        refreshLinkState()
        refreshRecordings()
    }

    // MARK: - Sterowanie zegarkiem

    func toggleStreaming() {
        let command: ControlCommand = isStreaming ? .stopLiveStream : .startLiveStream(sampleRate: 25)
        if !send(.control(command)) { return }
        isStreaming.toggle()
        if isStreaming { live.removeAll() }
    }

    func toggleRecording() {
        let recording = watchStatus?.isRecording ?? false
        let label = recordingLabel.trimmingCharacters(in: .whitespaces)
        send(.control(recording ? .stopRecording : .startRecording(label: label.isEmpty ? "nagranie" : label)))
    }

    func requestStatus() {
        send(.control(.requestStatus))
    }

    /// Seria pingów: RTT i przesunięcie zegarów (NTP).
    func measureLatency(pings: Int = 30) async {
        guard !isMeasuring else { return }
        isMeasuring = true
        defer { isMeasuring = false }
        for _ in 0..<pings {
            nextPingID &+= 1
            send(.ping(id: nextPingID, sentAt: MonotonicClock.now()))
            try? await Task.sleep(for: .milliseconds(150))
        }
    }

    func resetLatency() {
        clockSync = ClockSync(capacity: 64)
        transportLatencies.removeAll()
        sampleAges.removeAll()
        receivedMessages = 0
        lostMessages = 0
    }

    @discardableResult
    private func send(_ payload: WristPayload) -> Bool {
        let sent = link.send(payload)
        if !sent { errorMessage = "Zegarek nieosiągalny: otwórz Wrist Arena na zegarku." }
        return sent
    }

    // MARK: - Odbiór

    private func handle(_ message: WristMessage, receivedAt: TimeInterval) {
        receivedMessages += 1
        if let lastSeq, message.seq > lastSeq + 1 {
            lostMessages += Int(message.seq - lastSeq - 1)
        }
        lastSeq = message.seq
        errorMessage = nil

        switch message.payload {
        case .samples(let batch):
            live.append(contentsOf: batch)
            if let sentLocal = clockSync.toLocal(remote: message.sentAt) {
                transportLatencies.append(receivedAt - sentLocal)
            }
            if let last = batch.last, let sampleLocal = clockSync.toLocal(remote: last.t) {
                sampleAges.append(receivedAt - sampleLocal)
            }
        case .pong(_, let pingSentAt, let watchReceivedAt, let watchRepliedAt):
            clockSync.add(ClockSyncSample(t0: pingSentAt, t1: watchReceivedAt, t2: watchRepliedAt, t3: receivedAt))
        case .status(let status):
            watchStatus = status
            isStreaming = status.isStreaming
        case .throwEvent, .live, .phase, .ping, .control:
            break
        }
    }

    private func refreshLinkState() {
        isReachable = link.isReachable
        isPaired = link.isPaired
        isWatchAppInstalled = link.isWatchAppInstalled
        if isReachable { requestStatus() }
    }

    // MARK: - Nagrania

    func refreshRecordings() {
        recordings = (try? store?.list()) ?? []
    }

    func load(_ entry: RecordingStore.Entry) -> MotionRecording? {
        try? store?.load(entry.url)
    }

    func delete(_ entries: [RecordingStore.Entry]) {
        for entry in entries {
            try? store?.delete(entry.url)
        }
        refreshRecordings()
    }

    private func importFile(_ url: URL, name: String) {
        do {
            try store?.importFile(at: url, preferredName: name)
        } catch {
            errorMessage = "Import nagrania: \(error.localizedDescription)"
        }
        refreshRecordings()
    }

    // MARK: - Raport opóźnień

    var rttSummary: LatencySummary? { LatencySummary(values: clockSync.samples.map(\.roundTrip)) }
    var transportSummary: LatencySummary? { LatencySummary(values: transportLatencies.elements) }
    var sampleAgeSummary: LatencySummary? { LatencySummary(values: sampleAges.elements) }

    /// Tekst do wklejenia w docs/latency.md.
    var latencyReport: String {
        var lines = [
            "Pomiar: \(Date().formatted(date: .numeric, time: .shortened))",
            "iPhone: \(DeviceInfo.modelIdentifier), iOS \(UIDevice.current.systemVersion)",
            "",
            "| Pomiar | n | min [ms] | mediana [ms] | p90 [ms] | max [ms] |",
            "|---|---|---|---|---|---|"
        ]
        if let rtt = rttSummary { lines.append(rtt.markdownRow(name: "RTT ping-pong")) }
        if let transport = transportSummary { lines.append(transport.markdownRow(name: "Transport (jedna strona)")) }
        if let age = sampleAgeSummary { lines.append(age.markdownRow(name: "Wiek próbki przy odbiorze")) }
        lines.append("")
        lines.append("Wiadomości: \(receivedMessages), zgubione: \(lostMessages)")
        return lines.joined(separator: "\n")
    }

    func copyLatencyReport() {
        UIPasteboard.general.string = latencyReport
    }
}
