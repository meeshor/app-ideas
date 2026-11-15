import ArenaCore
import SwiftUI
import WristKit

@main
struct WristArenaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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
                        NavigationLink {
                            destination(for: module)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(module.name).font(.headline)
                                Text("Gest: \(module.requiredGesture.rawValue) · gracze \(module.playerRange.lowerBound)–\(module.playerRange.upperBound)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
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

    @ViewBuilder
    private func destination(for module: ModuleDescriptor) -> some View {
        switch module.id {
        case ModuleCatalog.darts.id:
            DartsSetupView()
        default:
            Text("Moduł \(module.name) jeszcze w budowie")
        }
    }
}

#Preview {
    HomeView(sensorLab: SensorLabModel())
}
