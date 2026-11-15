import ArenaCore
import Foundation
import Observation
import WristKit

/// Zapamiętani gracze (imię, nadgarstek, poziom, kalibracje) i ich statystyki, w `UserDefaults` jako JSON.
@MainActor
@Observable
final class PlayerStore {
    private(set) var profiles: [PlayerProfile] = []
    private(set) var stats: [PlayerProfile.ID: PlayerStats] = [:]

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let key = "wristarena.players.v1"
    @ObservationIgnored private let statsKey = "wristarena.stats.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([PlayerProfile].self, from: data) {
            profiles = decoded
        }
        if profiles.isEmpty {
            profiles = [PlayerProfile(name: "Gracz 1"), PlayerProfile(name: "Gracz 2")]
        }
        if let data = defaults.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode([PlayerProfile.ID: PlayerStats].self, from: data) {
            stats = decoded
        }
    }

    /// Dopisuje statystyki zakończonego meczu (wołać raz na mecz).
    func record(_ match: DartsMatch) {
        guard match.isFinished else { return }
        for matchStats in match.stats {
            stats[matchStats.player, default: PlayerStats()].add(matchStats, game: match.game)
        }
        if let data = try? JSONEncoder().encode(stats) {
            defaults.set(data, forKey: statsKey)
        }
    }

    func resetStats(for id: PlayerProfile.ID) {
        stats[id] = nil
        if let data = try? JSONEncoder().encode(stats) {
            defaults.set(data, forKey: statsKey)
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
