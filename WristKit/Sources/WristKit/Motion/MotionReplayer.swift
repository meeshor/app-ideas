import Foundation

/// Odtwarza nagranie: natychmiast (testy) albo w tempie rzeczywistym (tryb Replay w aplikacji).
public struct MotionReplayer: Sendable {
    public let recording: MotionRecording

    public init(recording: MotionRecording) {
        self.recording = recording
    }

    /// Przepuszcza całe nagranie przez recognizer i zwraca wszystkie wyjścia.
    public func run<R: GestureRecognizer>(_ recognizer: inout R) -> [GestureOutput<R.Event>] {
        var outputs: [GestureOutput<R.Event>] = []
        for sample in recording.samples {
            outputs.append(contentsOf: recognizer.process(sample))
        }
        return outputs
    }

    /// Same zdarzenia z nagrania.
    public func events<R: GestureRecognizer>(_ recognizer: inout R) -> [R.Event] {
        run(&recognizer).compactMap { output in
            if case .event(let event) = output { return event }
            return nil
        }
    }

    /// Strumień próbek w tempie nagrania (`rate` = 2 → dwa razy szybciej).
    public func stream(rate: Double = 1) -> AsyncStream<MotionSample> {
        let samples = recording.samples
        let rate = max(rate, 0.01)
        return AsyncStream { continuation in
            let task = Task {
                guard let first = samples.first else {
                    continuation.finish()
                    return
                }
                let start = ContinuousClock.now
                for sample in samples {
                    let offset = (sample.t - first.t) / rate
                    try? await Task.sleep(until: start + .seconds(offset), clock: .continuous)
                    if Task.isCancelled { break }
                    continuation.yield(sample)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
