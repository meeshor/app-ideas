import Foundation

/// Bufor cykliczny o stałej pojemności (np. ostatnie N sekund ruchu na wykresie).
public struct RingBuffer<Element: Sendable>: Sendable {
    public let capacity: Int
    private var storage: [Element] = []
    /// Indeks najstarszego elementu, gdy bufor jest pełny.
    private var head = 0

    public init(capacity: Int) {
        precondition(capacity > 0, "Pojemność musi być dodatnia")
        self.capacity = capacity
        storage.reserveCapacity(capacity)
    }

    public var count: Int { storage.count }
    public var isEmpty: Bool { storage.isEmpty }

    public mutating func append(_ element: Element) {
        if storage.count < capacity {
            storage.append(element)
        } else {
            storage[head] = element
            head = (head + 1) % capacity
        }
    }

    public mutating func append(contentsOf elements: some Sequence<Element>) {
        for element in elements {
            append(element)
        }
    }

    /// Elementy od najstarszego do najnowszego.
    public var elements: [Element] {
        guard storage.count == capacity, head > 0 else { return storage }
        return Array(storage[head...]) + Array(storage[..<head])
    }

    public var last: Element? {
        guard !storage.isEmpty else { return nil }
        if storage.count < capacity { return storage.last }
        return storage[(head - 1 + capacity) % capacity]
    }

    public mutating func removeAll() {
        storage.removeAll(keepingCapacity: true)
        head = 0
    }
}
