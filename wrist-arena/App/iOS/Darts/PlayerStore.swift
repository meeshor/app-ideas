import Foundation
import Observation
import WristKit

/// Zapamiętani gracze (imię, nadgarstek, poziom, kalibracje), w `UserDefaults` jako JSON.
@MainActor
@Observable
final class PlayerStore {
    private(set) var profiles: [PlayerProfile] = []

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let key = "wristarena.players.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([PlayerProfile].self, from: data) {
            profiles = decoded
        }
        if profiles.isEmpty {
            profiles = [PlayerProfile(name: "Gracz 1"), PlayerProfile(name: "Gracz 2")]
        }
    }

    func add() {
        profiles.append(PlayerProfile(name: "Gracz \(profiles.count + 1)"))
        save()
    }

    func update(_ profile: PlayerProfile) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        profiles[index] = profile
        save()
    }

    func remove(at offsets: IndexSet) {
        profiles.remove(atOffsets: offsets)
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        profiles.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func profile(id: PlayerProfile.ID) -> PlayerProfile? {
        profiles.first { $0.id == id }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(profiles) {
            defaults.set(data, forKey: key)
        }
    }
}
