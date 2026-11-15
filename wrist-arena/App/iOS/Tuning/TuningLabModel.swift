import ArenaCore
import Foundation
import Observation
import WristKit

/// Rzut odebrany w laboratorium strojenia (z chwilą odbioru).
struct TunedThrow: Identifiable, Hashable {
    var id: UUID { event.id }
    var event: ThrowEvent
    var receivedAt: Date
    var simulated: Bool
}

/// Laboratorium strojenia: sesja rozpoznawania na zegarku, progi wysyłane na żywo, lista ostatnich rzutów.
@MainActor
@Observable
final class TuningLabModel {
    private(set) var throwsReceived: [TunedThrow] = []
    private(set) var isSessionRunning = false
    private(set) var lastSent: Date?

    let store = TuningStore.shared
    @ObservationIgnored private let hub = PhoneLink.shared
    @ObservationIgnored private let handlerKey = "tuningLab"
    @ObservationIgnored private var sendTask: Task<Void, Never>?

    static let maxThrows = 30

    var phase: GesturePhase { hub.gesturePhase }
    var isReachable: Bool { hub.isReachable }

    func activate() {
        hub.activate()
        hub.addMessageHandler(handlerKey) { [weak self] message, _ in
            guard case .throwEvent(let event) = message.payload else { return }
            self?.append(event, simulated: false)
        }
    }

    func deactivate() {
        hub.removeMessageHandler(handlerKey)
        sendTask?.cancel()
    }

    func toggleSession() {
        if isSessionRunning {
            hub.send(.control(.stopSession))
            isSessionRunning = false
        } else {
            sendTuningNow()
            isSessionRunning = hub.send(.control(.startSession(kind: .flick)))
            hub.send(.control(.setActivePlayer(name: "Strojenie", wrist: hub.watchStatus?.wrist ?? .right)))
        }
    }

    /// Wysyła progi po krótkiej przerwie (suwak zmienia wartość wiele razy na sekundę).
    func scheduleSend() {
        sendTask?.cancel()
        sendTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            self?.sendTuningNow()
        }
    }

    func sendTuningNow() {
        if hub.send(.control(.updateTuning(store.gesture))) {
            lastSent = Date()
        }
    }

    /// Rzut syntetyczny przez recognizer z bieżącymi progami: czy te progi w ogóle przepuszczają „wzorcowy” rzut.
    func simulate(wrist: WristSide = .right) {
        guard let event = ThrowSimulator.throwEvent(wrist: wrist, tuning: store.gesture.flick) else {
            lastSimulationFailed = true
            return
        }
        lastSimulationFailed = false
        append(event, simulated: true)
    }

    private(set) var lastSimulationFailed = false

    func clear() {
        throwsReceived.removeAll()
    }

    /// Średnie z ostatnich rzutów (bez symulowanych) — punkt wyjścia do `referenceSpeed` i `jerkForUnit`.
    var averages: (speed: Double, jerk: Double, count: Int)? {
        let real = throwsReceived.filter { !$0.simulated }.map(\.event)
        guard !real.isEmpty else { return nil }
        let n = Double(real.count)
        return (real.map(\.speed).reduce(0, +) / n, real.map(\.jerk).reduce(0, +) / n, real.count)
    }

    private func append(_ event: ThrowEvent, simulated: Bool) {
        throwsReceived.insert(TunedThrow(event: event, receivedAt: Date(), simulated: simulated), at: 0)
        if throwsReceived.count > Self.maxThrows { throwsReceived.removeLast() }
    }
}
