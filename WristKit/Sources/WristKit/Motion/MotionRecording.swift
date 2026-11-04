import Foundation

/// Nagranie ruchu: metadane i próbki. Format pliku `.wkrec` to JSON.
public struct MotionRecording: Sendable, Hashable, Codable {
    public static let currentFormatVersion = 1
    public static let fileExtension = "wkrec"

    public struct Metadata: Sendable, Hashable, Codable {
        public var id: UUID
        public var createdAt: Date
        /// Opis nagrania, np. „flick_center_01”. Testy używają go jako nazwy przypadku.
        public var label: String
        public var wrist: WristSide
        /// Model urządzenia, np. „Watch7,1”.
        public var device: String
        /// Nominalna częstotliwość próbkowania, Hz.
        public var sampleRate: Double
        public var notes: String

        public init(
            id: UUID = UUID(),
            createdAt: Date = Date(),
            label: String,
            wrist: WristSide = .right,
            device: String = "unknown",
            sampleRate: Double = 100,
            notes: String = ""
        ) {
            self.id = id
            self.createdAt = createdAt
            self.label = label
            self.wrist = wrist
            self.device = device
            self.sampleRate = sampleRate
            self.notes = notes
        }
    }

    public var formatVersion: Int
    public var metadata: Metadata
    public var samples: [MotionSample]

    public init(metadata: Metadata, samples: [MotionSample]) {
        self.formatVersion = Self.currentFormatVersion
        self.metadata = metadata
        self.samples = samples
    }

    /// Czas trwania w sekundach.
    public var duration: TimeInterval {
        guard let first = samples.first, let last = samples.last else { return 0 }
        return last.t - first.t
    }

    public enum FormatError: Error, Equatable {
        case unsupportedVersion(Int)
    }

    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }

    public static func decode(from data: Data) throws -> MotionRecording {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let recording = try decoder.decode(MotionRecording.self, from: data)
        guard recording.formatVersion <= currentFormatVersion else {
            throw FormatError.unsupportedVersion(recording.formatVersion)
        }
        return recording
    }
}
