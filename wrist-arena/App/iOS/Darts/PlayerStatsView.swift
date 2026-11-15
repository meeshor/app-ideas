import ArenaCore
import SwiftUI
import WristKit

/// Statystyki graczy ze wszystkich zakończonych meczów.
struct PlayerStatsView: View {
    let store: PlayerStore
    @State private var confirmReset: PlayerProfile?

    var body: some View {
        List {
            ForEach(store.profiles) { player in
                Section(player.name) {
                    if let stats = store.stats[player.id], stats.matches > 0 {
                        PlayerStatsRows(stats: stats)
                        Button("Wyzeruj statystyki", role: .destructive) { confirmReset = player }
                    } else {
                        Text("Brak zakończonych meczów").foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Statystyki")
        .confirmationDialog(
            "Wyzerować statystyki gracza \(confirmReset?.name ?? "")?",
            isPresented: Binding(get: { confirmReset != nil }, set: { if !$0 { confirmReset = nil } }),
            titleVisibility: .visible
        ) {
            Button("Wyzeruj", role: .destructive) {
                if let player = confirmReset { store.resetStats(for: player.id) }
                confirmReset = nil
            }
        }
    }
}

private struct PlayerStatsRows: View {
    let stats: PlayerStats

    var body: some View {
        LabeledContent("Mecze / wygrane", value: "\(stats.matches) / \(stats.wins)")
        if let rate = stats.winRate {
            LabeledContent("Skuteczność", value: StatFormat.percent(rate))
        }
        LabeledContent("Rzutki", value: "\(stats.darts)")
        LabeledContent("Potrójne · podwójne · środek", value: "\(stats.triples) · \(stats.doubles) · \(stats.bulls)")
        if let miss = stats.missRate {
            LabeledContent("Pudła", value: StatFormat.percent(miss))
        }
        if stats.x01Matches > 0 {
            LabeledContent("X01: średnia (3 rzutki)", value: stats.x01Average.map(StatFormat.decimal) ?? "—")
            LabeledContent("X01: najlepsza tura", value: "\(stats.bestTurn)")
            LabeledContent("X01: najwyższe zamknięcie", value: stats.highestCheckout > 0 ? "\(stats.highestCheckout)" : "—")
            LabeledContent("X01: busty", value: "\(stats.busts)")
        }
        if stats.cricketMatches > 0 {
            LabeledContent("Cricket: MPR", value: stats.marksPerRound.map(StatFormat.decimal) ?? "—")
        }
        if stats.clockMatches > 0 {
            LabeledContent("Dookoła: celność", value: stats.clockAccuracy.map(StatFormat.percent) ?? "—")
            LabeledContent("Dookoła: najlepszy wynik", value: stats.bestClockFinish.map { "\($0) rzutek" } ?? "—")
        }
    }
}
