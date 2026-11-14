import SwiftUI
import WristKit
import WristKitDevice

@main
struct WristArenaWatchApp: App {
    @State private var model = WatchModel()

    var body: some Scene {
        WindowGroup {
            WatchHomeView(model: model)
                .task { model.activate() }
        }
    }
}

struct WatchHomeView: View {
    let model: WatchModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Label(
                    model.isReachable ? "Telefon połączony" : "Brak telefonu",
                    systemImage: model.isReachable ? "iphone.radiowaves.left.and.right" : "iphone.slash"
                )
                .font(.caption)
                .foregroundStyle(model.isReachable ? Color.green : Color.secondary)

                Button {
                    Task { await model.toggleRecording() }
                } label: {
                    Label(
                        model.isRecording ? "Stop" : "Nagrywaj",
                        systemImage: model.isRecording ? "stop.fill" : "record.circle"
                    )
                    .frame(maxWidth: .infinity)
                }
                .tint(model.isRecording ? .red : .accentColor)

                Text("\(model.label) · \(model.sampleCount) próbek · \(model.recordingDuration, format: .number.precision(.fractionLength(1))) s")
                    .font(.caption2)

                Text("|ω| \(model.rotationMagnitude, format: .number.precision(.fractionLength(2))) rad/s")
                    .font(.caption2.monospacedDigit())

                if model.isStreaming {
                    Label("Podgląd na żywo", systemImage: "waveform.path.ecg").font(.caption2)
                }
                if model.workoutActive {
                    Label("Sesja treningu", systemImage: "figure.mixed.cardio").font(.caption2)
                }
                if let saved = model.lastSavedName {
                    Text("Zapisano: \(saved)").font(.caption2).foregroundStyle(.secondary)
                }
                if let error = model.lastError {
                    Text(error).font(.caption2).foregroundStyle(.red)
                }
                Text("WristKit \(WristKitInfo.version)")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
