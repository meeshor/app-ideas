import ArenaCore
import SwiftUI
import WristKit

@main
struct WristArenaApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}

struct HomeView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Moduły") {
                    ForEach(ModuleCatalog.all) { module in
                        VStack(alignment: .leading) {
                            Text(module.name).font(.headline)
                            Text("Gest: \(module.requiredGesture.rawValue) · gracze \(module.playerRange.lowerBound)–\(module.playerRange.upperBound)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Wersje") {
                    LabeledContent("WristKit", value: WristKitInfo.version)
                    LabeledContent("ArenaCore", value: ArenaCoreInfo.version)
                }
            }
            .navigationTitle("Wrist Arena")
        }
    }
}

#Preview {
    HomeView()
}
