import Foundation

/// Przerzedza i pakuje próbki do wysyłki na telefon (podgląd na żywo).
///
/// 100 Hz w pojedynczych wiadomościach zapchałoby WatchConnectivity, więc
/// zostawiamy co `decimation`-tą próbkę i wysyłamy paczki co `maxInterval`
/// albo po `maxBatchSize` próbkach.
public struct SampleBatcher: Sendable {
    public var decimation: Int
    public var maxBatchSize: Int
    public var maxInterval: TimeInterval
    private var counter = 0
    private var pending: [MotionSample] = []

    /// Domyślnie: 100 Hz → 25 Hz, paczka co 0.2 s.
    public init(decimation: Int = 4, maxBatchSize: Int = 10, maxInterval: TimeInterval = 0.2) {
        self.decimation = max(1, decimation)
        self.maxBatchSize = max(1, maxBatchSize)
        self.maxInterval = maxInterval
    }

    /// Dodaje próbkę; zwraca paczkę, gdy jest gotowa do wysyłki.
    public mutating func add(_ sample: MotionSample) -> [MotionSample]? {
        defer { counter += 1 }
        guard counter % decimation == 0 else { return nil }
        pending.append(sample)
        if pending.count >= maxBatchSize || sample.t - pending[0].t >= maxInterval {
            return flush()
        }
        return nil
    }

    /// Oddaje to, co zostało w buforze.
    public mutating func flush() -> [MotionSample]? {
        guard !pending.isEmpty else { return nil }
        defer { pending = [] }
        return pending
    }

    public mutating func reset() {
        counter = 0
        pending = []
    }
}
