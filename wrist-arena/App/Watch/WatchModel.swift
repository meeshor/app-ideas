import Foundation
import Observation
import WristKit
import WristKitDevice

/// Stan aplikacji na zegarku: czujniki, nagrywanie, podgląd na żywo i sesja gry (rozpoznawanie rzutów).
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

    // Sesja gry
    private(set) var sessionKind: ThrowKind?
    private(set) var playerName: String?
    private(set) var gesturePhase: GesturePhase = .idle
    private(set) var throwCount = 0
    private(set) var lastThrow: ThrowEvent?

    private let motion = LiveMotionSource()
    private let workout = WorkoutSessionController()
    private let link = WatchLink.shared
    private let store = try? RecordingStore(directory: RecordingStore.defaultDirectory())
    private var recorder = MotionRecorder(maxDuration: 120)
    private var batcher = SampleBatcher()
    private var recognizer: ThrowRecognizer = .flick(FlickThrowRecognizer())
    /// Ostatnie progi z telefonu (dla każdego gestu), stosowane też po zmianie gry.
    private var tuning = GestureTuning.default
    private var motionTask: Task<Void, Never>?
    private var uiCounter = 0

    var motionAvailable: Bool { motion.isAvailable }
    var isSessionActive: Bool { sessionKind != nil }

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

    // MARK: - Sesja gry

    func startSession(kind: ThrowKind) async {
        guard let selected = ThrowRecognizer(kind: kind, tuning: tuning, orientation: DeviceInfo.orientation) else {
            lastError = "Gest \(kind.rawValue) jeszcze nieobsługiwany"
            sendStatus()
            return
        }
        recognizer = selected
        sessionKind = kind
        throwCount = 0
        lastThrow = nil
        gesturePhase = recognizer.phase
        await startMotionIfNeeded()
        Haptics.start()
        sendStatus()
    }

    func stopSession() {
        guard sessionKind != nil else { return }
        sessionKind = nil
        playerName = nil
        recognizer.reset()
        gesturePhase = .idle
        stopMotionIfIdle()
        sendStatus()
    }

    private func setActivePlayer(name: String, wrist: WristSide) {
        playerName = name
        // Przy pass & play gracz zakłada zegarek na swój nadgarstek; zakładamy koronkę od strony dłoni,
        // chyba że to ten sam nadgarstek co w ustawieniach zegarka (wtedy bierzemy ustawienia).
        let device = DeviceInfo.orientation
        recognizer.orientation = wrist == device.wrist ? device : WristOrientation(wrist: wrist)
        recognizer.reset()
        gesturePhase = recognizer.phase
        Haptics.click()
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
            // Bez sesji treningu działamy dalej, ale tylko przy włączonym ekranie.
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
        guard !isRecording, !isStreaming, sessionKind == nil else { return }
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
        if sessionKind != nil {
            for output in recognizer.process(sample) {
                handle(output)
            }
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

    private func handle(_ output: GestureOutput<ThrowEvent>) {
        switch output {
        case .phaseChanged(let phase):
            gesturePhase = phase
            link.send(.phase(phase))
            if phase == .ready { Haptics.click() }
        case .event(let event):
            link.send(.throwEvent(event))
            if event.isFeint {
                Haptics.click()
            } else {
                throwCount += 1
                lastThrow = event
                Haptics.success()
            }
        case .live(let state):
            link.send(.live(state))
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
        case .startSession(let kind):
            Task { await startSession(kind: kind) }
        case .stopSession:
            stopSession()
        case .setActivePlayer(let name, let wrist):
            setActivePlayer(name: name, wrist: wrist)
        case .updateTuning(let tuning):
            self.tuning = tuning
            recognizer.apply(tuning)
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
            lastError: lastError,
            sessionKind: sessionKind
        )))
    }
}
