import Foundation

/// Wykrywa, że ręka jest nieruchoma przez zadany czas.
/// Cegiełka dla wszystkich recognizerów (poza „ready”).
public struct StillnessDetector: Sendable, Hashable {
    public var tuning: StillnessTuning
    private var stillSince: TimeInterval?

    public init(tuning: StillnessTuning = StillnessTuning()) {
        self.tuning = tuning
    }

    /// Czy pojedyncza próbka mieści się w progach spoczynku.
    public func isStill(_ sample: MotionSample) -> Bool {
        sample.rotationRate.length <= tuning.maxRotationRate
            && sample.userAcceleration.length <= tuning.maxUserAcceleration
    }

    /// Zwraca `true`, gdy ręka jest nieruchoma co najmniej `tuning.minDuration`.
    public mutating func process(_ sample: MotionSample) -> Bool {
        guard isStill(sample) else {
            stillSince = nil
            return false
        }
        let start = stillSince ?? sample.t
        stillSince = start
        return sample.t - start >= tuning.minDuration
    }

    public mutating func reset() {
        stillSince = nil
    }
}
