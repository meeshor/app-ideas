import Foundation

/// Katalog z nagraniami `.wkrec` (na zegarku i na telefonie).
public struct RecordingStore: Sendable {
    public struct Entry: Sendable, Hashable, Identifiable {
        public var url: URL
        public var name: String { url.deletingPathExtension().lastPathComponent }
        public var size: Int
        public var modified: Date
        public var id: URL { url }
    }

    public let directory: URL

    public init(directory: URL) throws {
        self.directory = directory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// `Documents/Recordings` aplikacji.
    public static func defaultDirectory() throws -> URL {
        try FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Recordings", isDirectory: true)
    }

    /// Nagrania od najnowszego.
    public func list() throws -> [Entry] {
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
        let urls = try FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: keys
        )
        return try urls
            .filter { $0.pathExtension == MotionRecording.fileExtension }
            .map { url in
                let values = try url.resourceValues(forKeys: Set(keys))
                return Entry(
                    url: url,
                    size: values.fileSize ?? 0,
                    modified: values.contentModificationDate ?? .distantPast
                )
            }
            .sorted { $0.modified > $1.modified }
    }

    @discardableResult
    public func save(_ recording: MotionRecording) throws -> URL {
        let url = uniqueURL(for: recording.suggestedFileName)
        try recording.encoded().write(to: url, options: .atomic)
        return url
    }

    public func load(_ url: URL) throws -> MotionRecording {
        try MotionRecording.decode(from: Data(contentsOf: url))
    }

    /// Przenosi plik (np. odebrany z zegarka) do katalogu, nie nadpisując istniejących.
    @discardableResult
    public func importFile(at source: URL, preferredName: String? = nil) throws -> URL {
        let destination = uniqueURL(for: preferredName ?? source.lastPathComponent)
        try FileManager.default.moveItem(at: source, to: destination)
        return destination
    }

    public func delete(_ url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }

    private func uniqueURL(for fileName: String) -> URL {
        let base = (fileName as NSString).deletingPathExtension
        let ext = MotionRecording.fileExtension
        var candidate = directory.appendingPathComponent("\(base).\(ext)")
        var index = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(base)-\(index).\(ext)")
            index += 1
        }
        return candidate
    }
}

extension MotionRecording {
    /// Nazwa pliku: `<etykieta>_<yyyyMMdd-HHmmss UTC>.wkrec`.
    public var suggestedFileName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let label = Self.sanitize(metadata.label)
        return "\(label.isEmpty ? "nagranie" : label)_\(formatter.string(from: metadata.createdAt)).\(Self.fileExtension)"
    }

    static func sanitize(_ label: String) -> String {
        let mapped = label.map { character -> String in
            if character.isLetter || character.isNumber || character == "-" || character == "_" {
                return String(character)
            }
            return character.isWhitespace ? "_" : ""
        }
        return mapped.joined()
    }
}
