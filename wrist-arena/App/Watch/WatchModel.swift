import Foundation
import Observation
import WristKit
import WristKitDevice

/// Stan aplikacji na zegarku: czujniki, nagrywanie, podgląd na żywo dla telefonu.
@MainActor
@Observable
final class WatchModel {
    private(set) var isRecording = false
    private(set) var isStreaming = false
    private(set) var workoutActive = false
    private(set) var sampleCount = 0
    private(set) var recordingDuration: TimeInterval = 0
    private(set) var rotationMagnitude: Double = 0
    private(set) var isReachable = false
    private(set) var lastError: String?
    private(set) var lastSavedName: String?
    var label = "nagranie"

    private let motion = LiveMotionSource()
    private let workout = WorkoutSessionController()
    private let link = WatchLink.shared
    private let store = try? RecordingStore(directory: RecordingStore.defaultDirectory())
    private var recorder = MotionRecorder(maxDuration: 120)
    private var batcher = SampleBatcher()
    private var motionTask: Task<Void, Never>?
    private var uiCounter = 0

    var motionAvailable: Bool { motion.isAvailable }

    func activate() {
        link.onMessage = { [weak self] message, _ in self?.handle(message) }
        link.onStateChange = { [weak self] in
            guard let self else { return }
            isReachable = link.isReachable
            sendStatus()
        }
        link.activate()
    }

    // MARK: - Nagrywanie

    func toggleRecording() async {
        if isRecording {
            stopRecording()
        } else {
            await startRecording(label: label)
        }
    }

    func startRecording(label: String) async {
        guard !isRecording else { return }
        self.label = label
        recorder = MotionRecorder(maxDuration: 120)
        sampleCount = 0
        recordingDuration = 0
        isRecording = true
        await startMotionIfNeeded()
        Haptics.start()
        sendStatus()
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        let recording = recorder.finish(metadata: .init(
            label: label,
            wrist: DeviceInfo.wrist,
            device: DeviceInfo.modelIdentifier,
            sampleRate: 100
        ))
        Haptics.stop()
        if recording.samples.isEmpty {
            lastError = "Brak próbek"
        } else if let store {
            do {
                let url = try store.save(recording)
                lastSavedName = url.deletingPathExtension().lastPathComponent
                link.transferFile(url)
            } catch {
                lastError = "Zapis: \(error.localizedDescription)"
            }
        }
        stopMotionIfIdle()
        sendStatus()
    }

    // MARK: - Podgląd na żywo

    func setStreaming(_ enabled: Bool, sampleRate: Double = 25) async {
        isStreaming = enabled
        if enabled {
            batcher = SampleBatcher(decimation: max(1, Int((100 / sampleRate).rounded())))
            await startMotionIfNeeded()
        } else {
            stopMotionIfIdle()
        }
        sendStatus()
    }

    // MARK: - Czujniki

    private func startMotionIfNeeded() async {
        guard motionTask == nil else { return }
        guard motion.isAvailable else {
            lastError = "Czujniki ruchu niedostępne"
            return
        }
        do {
            try await workout.start()
            workoutActive = workout.isRunning
        } catch {
            // Bez sesji treningu nagrywamy dalej, ale tylko przy włączonym ekranie.
            lastError = "Trening: \(error.localizedDescription)"
        }
        let stream = motion.start(frequency: 100)
        motionTask = Task { [weak self] in
            for await sample in stream {
                self?.process(sample)
            }
        }
    }

    private func stopMotionIfIdle() {
        guard !isRecording, !isStreaming else { return }
        motion.stop()
        motionTask?.cancel()
        motionTask = nil
        workout.stop()
        workoutActive = false
    }

    private func process(_ sample: MotionSample) {
        if isRecording {
            recorder.append(sample)
            if recorder.isFull { stopRecording() }
        }
        if isStreaming, let batch = batcher.add(sample) {
            link.send(.samples(batch))
        }
        // UI odświeżamy ~10 Hz, nie 100 Hz.
        uiCounter += 1
        if uiCounter % 10 == 0 {
            rotationMagnitude = sample.rotationRate.length
            sampleCount = recorder.samples.count
            recordingDuration = recorder.duration
        }
        if uiCounter % 100 == 0, isRecording {
            sendStatus()
        }
    }

    // MARK: - Wiadomości z telefonu

    private func handle(_ message: WristMessage) {
        guard case .control(let command) = message.payload else { return }
        switch command {
        case .startRecording(let label):
            Task { await startRecording(label: label) }
        case .stopRecording:
            stopRecording()
        case .startLiveStream(let rate):
            Task { await setStreaming(true, sampleRate: rate) }
        case .stopLiveStream:
            Task { await setStreaming(false) }
        case .requestStatus:
            sendStatus()
        case .startSession, .stopSession, .setActivePlayer, .updateTuning:
            break // M2
        }
    }

    private func sendStatus() {
        link.send(.status(WatchStatus(
            isRecording: isRecording,
            recordingDuration: recorder.duration,
            sampleCount: recorder.samples.count,
            isStreaming: isStreaming,
            workoutActive: workoutActive,
            motionAvailable: motion.isAvailable,
            wrist: DeviceInfo.wrist,
            lastError: lastError
        )))
    }
}
