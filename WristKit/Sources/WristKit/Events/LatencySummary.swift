import Foundation

/// Zegar monotoniczny wspólny dla próbek i wiadomości: sekundy od uruchomienia
/// urządzenia, ta sama podstawa co `CMLogItem.timestamp`.
public enum MonotonicClock {
    public static func now() -> TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }
}

/// Podsumowanie serii pomiarów opóźnienia (sekundy).
public struct LatencySummary: Sendable, Hashable {
    public var count: Int
    public var min: Double
    public var median: Double
    public var p90: Double
    public var max: Double

    public init?(values: [Double]) {
        let sorted = values.filter(\.isFinite).sorted()
        guard let first = sorted.first, let last = sorted.last else { return nil }
        count = sorted.count
        min = first
        max = last
        median = Self.percentile(sorted: sorted, 0.5)
        p90 = Self.percentile(sorted: sorted, 0.9)
    }

    /// Percentyl z interpolacją liniową; `sorted` musi być posortowane rosnąco i niepuste.
    public static func percentile(sorted: [Double], _ p: Double) -> Double {
        precondition(!sorted.isEmpty)
        let position = Swift.max(0, Swift.min(1, p)) * Double(sorted.count - 1)
        let lower = Int(position.rounded(.down))
        let upper = Swift.min(lower + 1, sorted.count - 1)
        let fraction = position - Double(lower)
        return sorted[lower] + (sorted[upper] - sorted[lower]) * fraction
    }

    /// Wiersz do tabeli w docs/latency.md (milisekundy).
    public func markdownRow(name: String) -> String {
        func ms(_ value: Double) -> String { String(format: "%.0f", value * 1000) }
        return "| \(name) | \(count) | \(ms(min)) | \(ms(median)) | \(ms(p90)) | \(ms(max)) |"
    }
}

/// Stan zegarka raportowany na telefon.
public struct WatchStatus: Sendable, Hashable, Codable {
    public var isRecording: Bool
    public var recordingDuration: TimeInterval
    public var sampleCount: Int
    public var isStreaming: Bool
    public var workoutActive: Bool
    public var motionAvailable: Bool
    public var wrist: WristSide
    public var lastError: String?
    /// Aktywna sesja gry (rozpoznawanie gestu) albo `nil`.
    public var sessionKind: ThrowKind?

    public init(
        isRecording: Bool = false,
        recordingDuration: TimeInterval = 0,
        sampleCount: Int = 0,
        isStreaming: Bool = false,
        workoutActive: Bool = false,
        motionAvailable: Bool = false,
        wrist: WristSide = .right,
        lastError: String? = nil,
        sessionKind: ThrowKind? = nil
    ) {
        self.isRecording = isRecording
        self.recordingDuration = recordingDuration
        self.sampleCount = sampleCount
        self.isStreaming = isStreaming
        self.workoutActive = workoutActive
        self.motionAvailable = motionAvailable
        self.wrist = wrist
        self.lastError = lastError
        self.sessionKind = sessionKind
    }
}
