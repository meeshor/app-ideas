import ArenaCore
import Foundation
import Observation
import WristKit

/// Bieżące progi gestu (wysyłane na zegarek) i modelu tarczy (używane w nowych meczach).
/// Zapisywane w `UserDefaults`, żeby strojenie na zegarku przetrwało restart aplikacji.
@MainActor
@Observable
final class TuningStore {
    static let shared = TuningStore()

    var gesture: GestureTuning {
        didSet { save() }
    }
    var darts: DartsTuning {
        didSet { save() }
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let gestureKey = "wristarena.tuning.gesture.v1"
    @ObservationIgnored private let dartsKey = "wristarena.tuning.darts.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        gesture = defaults.data(forKey: gestureKey)
            .flatMap { try? JSONDecoder().decode(GestureTuning.self, from: $0) } ?? .default
        darts = defaults.data(forKey: dartsKey)
            .flatMap { try? JSONDecoder().decode(DartsTuning.self, from: $0) } ?? .default
    }

    var isDefault: Bool { gesture == .default && darts == .default }

    func resetGesture() { gesture = .default }
    func resetDarts() { darts = .default }

    /// JSON obu zestawów (do wklejenia w issue / docs/tuning.md po strojeniu).
    var exportJSON: String {
        struct Export: Encodable {
            var gesture: GestureTuning
            var darts: DartsTuning
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(Export(gesture: gesture, darts: darts)) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(gesture) { defaults.set(data, forKey: gestureKey) }
        if let data = try? JSONEncoder().encode(darts) { defaults.set(data, forKey: dartsKey) }
    }
}
