#if os(watchOS)
import Foundation
import HealthKit

/// Sesja treningu (`HKWorkoutSession`): pozwala zbierać ruch z opuszczonym
/// nadgarstkiem i wygaszonym ekranem. Treningu nie zapisujemy w Zdrowiu.
@MainActor
public final class WorkoutSessionController {
    public enum WorkoutError: Error {
        case healthDataUnavailable
    }

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?

    public private(set) var isRunning = false

    public init() {}

    public func start() async throws {
        guard !isRunning else { return }
        guard HKHealthStore.isHealthDataAvailable() else { throw WorkoutError.healthDataUnavailable }
        try await requestAuthorization()

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .indoor
        let session = try HKWorkoutSession(healthStore: store, configuration: configuration)
        session.startActivity(with: Date())
        self.session = session
        isRunning = true
    }

    public func stop() {
        session?.end()
        session = nil
        isRunning = false
    }

    private func requestAuthorization() async throws {
        let types: Set<HKSampleType> = [HKObjectType.workoutType()]
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            store.requestAuthorization(toShare: types, read: nil) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
#endif
