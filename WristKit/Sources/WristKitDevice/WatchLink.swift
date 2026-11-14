#if os(watchOS) || os(iOS)
import Foundation
import WatchConnectivity
import WristKit

/// Most WatchConnectivity, ten sam kod po obu stronach (zegarek i telefon).
///
/// - wiadomości: `WristMessage` przez `sendMessageData` (wymaga, żeby druga strona była osiągalna),
/// - pliki (nagrania): `transferFile`, kolejkowane przez system także bez połączenia,
/// - pingi są obsługiwane od razu na wątku WatchConnectivity (bez skoku na główny wątek),
///   żeby pomiar opóźnienia nie zawierał czasu oczekiwania na UI.
@MainActor
public final class WatchLink: NSObject {
    public static let shared = WatchLink()

    public private(set) var isActivated = false
    public private(set) var isReachable = false

    /// Wiadomość i chwila odbioru (`MonotonicClock`).
    public var onMessage: (@MainActor (WristMessage, TimeInterval) -> Void)?
    /// Odebrany plik, już przeniesiony do katalogu tymczasowego, i jego oryginalna nazwa.
    public var onFile: (@MainActor (URL, String) -> Void)?
    public var onStateChange: (@MainActor () -> Void)?

    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    nonisolated private let sequence = SequenceCounter()

    override private init() {
        super.init()
    }

    public func activate() {
        guard let session, session.delegate == nil else { return }
        session.delegate = self
        session.activate()
    }

    #if os(iOS)
    public var isPaired: Bool { session?.isPaired ?? false }
    public var isWatchAppInstalled: Bool { session?.isWatchAppInstalled ?? false }
    #endif

    /// Wysyła wiadomość, jeśli druga strona jest osiągalna. Zwraca `false`, gdy nie wysłano.
    @discardableResult
    public func send(_ payload: WristPayload) -> Bool {
        guard let session else { return false }
        return Self.send(payload, over: session, seq: sequence.next())
    }

    /// Przesyła plik nagrania na drugie urządzenie (w tle, z kolejkowaniem).
    public func transferFile(_ url: URL) {
        guard let session, session.activationState == .activated else { return }
        session.transferFile(url, metadata: ["fileName": url.lastPathComponent])
    }

    nonisolated private static func send(_ payload: WristPayload, over session: WCSession, seq: UInt64) -> Bool {
        guard session.activationState == .activated, session.isReachable else { return false }
        let message = WristMessage(seq: seq, sentAt: MonotonicClock.now(), payload: payload)
        guard let data = try? message.encoded() else { return false }
        session.sendMessageData(data, replyHandler: nil, errorHandler: nil)
        return true
    }
}

extension WatchLink: WCSessionDelegate {
    nonisolated public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        let activated = activationState == .activated
        let reachable = session.isReachable
        Task { @MainActor in
            self.isActivated = activated
            self.isReachable = reachable
            self.onStateChange?()
        }
    }

    nonisolated public func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in
            self.isReachable = reachable
            self.onStateChange?()
        }
    }

    #if os(iOS)
    nonisolated public func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated public func sessionDidDeactivate(_ session: WCSession) {
        // Użytkownik przełączył zegarek: aktywujemy sesję dla nowego.
        session.activate()
    }

    nonisolated public func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in self.onStateChange?() }
    }
    #endif

    nonisolated public func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        let receivedAt = MonotonicClock.now()
        guard let message = try? WristMessage.decode(from: messageData) else { return }
        if case .ping(let id, let sentAt) = message.payload {
            let pong = WristPayload.pong(
                id: id, pingSentAt: sentAt, receivedAt: receivedAt, repliedAt: MonotonicClock.now()
            )
            _ = Self.send(pong, over: session, seq: sequence.next())
            return
        }
        Task { @MainActor in self.onMessage?(message, receivedAt) }
    }

    nonisolated public func session(_ session: WCSession, didReceive file: WCSessionFile) {
        // Plik trzeba przenieść przed powrotem z tej metody, potem system go usuwa.
        let name = (file.metadata?["fileName"] as? String) ?? file.fileURL.lastPathComponent
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("incoming-\(UUID().uuidString)-\(name)")
        do {
            try FileManager.default.moveItem(at: file.fileURL, to: destination)
        } catch {
            return
        }
        Task { @MainActor in self.onFile?(destination, name) }
    }

    nonisolated public func session(
        _ session: WCSession,
        didFinish fileTransfer: WCSessionFileTransfer,
        error: (any Error)?
    ) {
        // Nadawca: po udanym przesłaniu usuwamy lokalną kopię (miejsce na zegarku jest cenne).
        guard error == nil else { return }
        try? FileManager.default.removeItem(at: fileTransfer.file.fileURL)
    }
}

/// Licznik numerów kolejnych, bezpieczny wątkowo (używany też poza głównym wątkiem).
final class SequenceCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value: UInt64 = 0

    func next() -> UInt64 {
        lock.withLock {
            value += 1
            return value
        }
    }
}
#endif
