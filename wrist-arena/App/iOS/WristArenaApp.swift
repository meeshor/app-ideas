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
                                let range = module.playerRange
                                Text("Gest: \(module.requiredGesture.rawValue) · gracze \(range.lowerBound)–\(range.upperBound)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("Narzędzia") {
                    NavigationLink {
                        TuningLabView()
                    } label: {
                        Label("Strojenie gestu", systemImage: "slider.horizontal.3")
                    }
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
        case ModuleCatalog.handball.id:
            HandballSetupView()
        default:
            Text("Moduł \(module.name) jeszcze w budowie")
        }
    }
}

#Preview {
    HomeView(sensorLab: SensorLabModel())
}
