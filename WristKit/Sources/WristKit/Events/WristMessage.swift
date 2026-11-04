import Foundation

/// Polecenie sterujące telefon → zegarek.
public enum ControlCommand: Sendable, Hashable, Codable {
    case startSession(kind: ThrowKind)
    case stopSession
    case setActivePlayer(name: String, wrist: WristSide)
    case startRecording(label: String)
    case stopRecording
    case updateTuning(GestureTuning)
}

/// Zawartość wiadomości między zegarkiem a telefonem.
public enum WristPayload: Sendable, Hashable, Codable {
    case throwEvent(ThrowEvent)
    case live(LiveGestureState)
    case phase(GesturePhase)
    /// Pomiar opóźnienia: `sentAt` według zegara nadawcy.
    case ping(id: UInt32, sentAt: TimeInterval)
    /// Odpowiedź na ping: czasy według zegara odpowiadającego.
    case pong(id: UInt32, pingSentAt: TimeInterval, receivedAt: TimeInterval, repliedAt: TimeInterval)
    case control(ControlCommand)
}

/// Koperta transportowa (WatchConnectivity). Wersjonowana, żeby stara apka
/// na zegarku nie wywróciła się na nowym formacie z telefonu.
public struct WristMessage: Sendable, Hashable, Codable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    /// Numer kolejny nadawcy (wykrywanie zgubionych i zdublowanych wiadomości).
    public var seq: UInt64
    /// Chwila wysłania według zegara nadawcy.
    public var sentAt: TimeInterval
    public var payload: WristPayload

    public init(seq: UInt64, sentAt: TimeInterval, payload: WristPayload) {
        self.schemaVersion = Self.currentSchemaVersion
        self.seq = seq
        self.sentAt = sentAt
        self.payload = payload
    }

    public enum DecodeError: Error, Equatable {
        case unsupportedSchema(Int)
    }

    public func encoded() throws -> Data {
        try JSONEncoder().encode(self)
    }

    public static func decode(from data: Data) throws -> WristMessage {
        let message = try JSONDecoder().decode(WristMessage.self, from: data)
        guard message.schemaVersion <= currentSchemaVersion else {
            throw DecodeError.unsupportedSchema(message.schemaVersion)
        }
        return message
    }
}
