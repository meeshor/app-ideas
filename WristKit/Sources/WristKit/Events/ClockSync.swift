import Foundation

/// Jeden pomiar ping-pong (metoda jak w NTP).
///
/// - `t0`: wysłanie pinga (zegar A)
/// - `t1`: odbiór pinga (zegar B)
/// - `t2`: wysłanie ponga (zegar B)
/// - `t3`: odbiór ponga (zegar A)
public struct ClockSyncSample: Sendable, Hashable, Codable {
    public var t0: TimeInterval
    public var t1: TimeInterval
    public var t2: TimeInterval
    public var t3: TimeInterval

    public init(t0: TimeInterval, t1: TimeInterval, t2: TimeInterval, t3: TimeInterval) {
        self.t0 = t0
        self.t1 = t1
        self.t2 = t2
        self.t3 = t3
    }

    /// Czas podróży w obie strony bez czasu przetwarzania po stronie B.
    public var roundTrip: TimeInterval { (t3 - t0) - (t2 - t1) }

    /// Szacowane przesunięcie zegara B względem A (B − A).
    public var offset: TimeInterval { ((t1 - t0) + (t2 - t3)) / 2 }
}

/// Estymacja przesunięcia zegarów z wielu pomiarów: bierzemy pomiar o najkrótszym RTT
/// (najmniej zaburzony kolejkowaniem w Bluetooth).
public struct ClockSync: Sendable {
    public private(set) var samples: [ClockSyncSample] = []
    public var capacity: Int

    public init(capacity: Int = 32) {
        self.capacity = capacity
    }

    public mutating func add(_ sample: ClockSyncSample) {
        samples.append(sample)
        if samples.count > capacity {
            samples.removeFirst(samples.count - capacity)
        }
    }

    public var best: ClockSyncSample? { samples.min { $0.roundTrip < $1.roundTrip } }

    /// Przesunięcie zegara B względem A (B − A) albo `nil` bez pomiarów.
    public var offset: TimeInterval? { best?.offset }

    /// Mediana RTT, s.
    public var medianRoundTrip: TimeInterval? {
        guard !samples.isEmpty else { return nil }
        let sorted = samples.map(\.roundTrip).sorted()
        let mid = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
    }

    /// Przelicza czas z zegara B na zegar A.
    public func toLocal(remote time: TimeInterval) -> TimeInterval? {
        offset.map { time - $0 }
    }
}
