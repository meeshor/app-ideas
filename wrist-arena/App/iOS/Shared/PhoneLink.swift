import Foundation
import Observation
import WristKit
import WristKitDevice

/// Jedno miejsce odbioru wiadomości z zegarka na telefonie.
///
/// `WatchLink` ma pojedyncze callbacki, a słuchają go różne ekrany (Czujniki, kalibracja, gra).
/// `PhoneLink` rozsyła wiadomości do zarejestrowanych odbiorców i trzyma wspólny stan połączenia.
@MainActor
@Observable
final class PhoneLink {
    static let shared = PhoneLink()

    private(set) var isReachable = false
    private(set) var isPaired = false
    private(set) var isWatchAppInstalled = false
    /// Ostatni status zgłoszony przez zegarek.
    private(set) var watchStatus: WatchStatus?
    /// Faza gestu raportowana przez zegarek w trakcie sesji gry.
    private(set) var gesturePhase: GesturePhase = .idle

    @ObservationIgnored private var messageHandlers: [String: @MainActor (WristMessage, TimeInterval) -> Void] = [:]
    @ObservationIgnored private var stateHandlers: [String: @MainActor () -> Void] = [:]
    @ObservationIgnored var onFile: (@MainActor (URL, String) -> Void)?
    @ObservationIgnored private let link = WatchLink.shared
    @ObservationIgnored private var activated = false

    private init() {}

    func activate() {
        guard !activated else { return }
        activated = true
        link.onMessage = { [weak self] message, receivedAt in
            self?.dispatch(message, receivedAt: receivedAt)
        }
        link.onFile = { [weak self] url, name in
            self?.onFile?(url, name)
        }
        link.onStateChange = { [weak self] in
            self?.refresh()
        }
        link.activate()
        refresh()
    }

    /// Rejestruje odbiorcę wiadomości (ten sam klucz = podmiana).
    func addMessageHandler(_ key: String, _ handler: @escaping @MainActor (WristMessage, TimeInterval) -> Void) {
        messageHandlers[key] = handler
    }

    func removeMessageHandler(_ key: String) {
        messageHandlers[key] = nil
    }

    /// Rejestruje odbiorcę zmian połączenia (osiągalność, parowanie).
    func addStateHandler(_ key: String, _ handler: @escaping @MainActor () -> Void) {
        stateHandlers[key] = handler
    }

    @discardableResult
    func send(_ payload: WristPayload) -> Bool {
        link.send(payload)
    }

    private func dispatch(_ message: WristMessage, receivedAt: TimeInterval) {
        switch message.payload {
        case .status(let status):
            watchStatus = status
        case .phase(let phase):
            gesturePhase = phase
        default:
            break
        }
        for handler in messageHandlers.values {
            handler(message, receivedAt)
        }
    }

    private func refresh() {
        isReachable = link.isReachable
        isPaired = link.isPaired
        isWatchAppInstalled = link.isWatchAppInstalled
        if isReachable { send(.control(.requestStatus)) }
        for handler in stateHandlers.values {
            handler()
        }
    }
}
