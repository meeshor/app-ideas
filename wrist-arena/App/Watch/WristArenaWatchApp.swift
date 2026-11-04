import SwiftUI
import WristKit
import WristKitDevice

@main
struct WristArenaWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
    }
}

struct WatchHomeView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "target")
                .font(.title2)
            Text("Wrist Arena")
                .font(.headline)
            Text("WristKit \(WristKitInfo.version)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(WristKitDeviceInfo.isSupported ? "Czujniki: OK" : "Czujniki: brak")
                .font(.caption2)
        }
    }
}

#Preview {
    WatchHomeView()
}
