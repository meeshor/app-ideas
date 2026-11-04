import Foundation

/// Zbiera próbki do nagrania. Czysta wartość: wątki i Core Motion obsługuje warstwa urządzenia.
public struct MotionRecorder: Sendable {
    /// Limit długości nagrania (żeby nie zapchać pamięci zegarka), s.
    public var maxDuration: TimeInterval
    public private(set) var samples: [MotionSample] = []

    public init(maxDuration: TimeInterval = 120) {
        self.maxDuration = maxDuration
    }

    public var duration: TimeInterval {
        guard let first = samples.first, let last = samples.last else { return 0 }
        return last.t - first.t
    }

    public var isFull: Bool { duration >= maxDuration }

    /// Dodaje próbkę. Zwraca `false`, gdy nagranie osiągnęło limit albo próbka cofa się w czasie.
    @discardableResult
    public mutating func append(_ sample: MotionSample) -> Bool {
        if let last = samples.last, sample.t < last.t { return false }
        guard !isFull else { return false }
        samples.append(sample)
        return true
    }

    /// Kończy nagranie i czyści bufor.
    public mutating func finish(metadata: MotionRecording.Metadata) -> MotionRecording {
        defer { samples = [] }
        return MotionRecording(metadata: metadata, samples: samples)
    }
}
