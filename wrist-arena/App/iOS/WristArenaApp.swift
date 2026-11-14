import ArenaCore
import SwiftUI
import WristKit

@main
struct WristArenaApp: App {
    @State private var sensorLab = SensorLabModel()

    var body: some Scene {
        WindowGroup {
            HomeView(sensorLab: sensorLab)
                .task { sensorLab.activate() }
        }
    }
}

struct HomeView: View {
    let sensorLab: SensorLabModel

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
                Section("Narzędzia") {
                    NavigationLink {
                        SensorLabView(model: sensorLab)
                    } label: {
                        Label("Czujniki (debug)", systemImage: "waveform.path.ecg")
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
    HomeView(sensorLab: SensorLabModel())
}
