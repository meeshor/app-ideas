import SwiftUI
import WristKit
import WristKitDevice

@main
struct WristArenaWatchApp: App {
    @State private var model = WatchModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if model.isSessionActive {
                    WatchGameView(model: model)
                } else {
                    WatchHomeView(model: model)
                }
            }
            .task { model.activate() }
        }
    }
}

/// Ekran w trakcie gry: kto rzuca i czy ręka jest gotowa. Gracz patrzy na telefon/TV,
/// więc tu tylko duży, czytelny stan i haptyka.
struct WatchGameView: View {
    let model: WatchModel

    var body: some View {
        VStack(spacing: 6) {
            if let name = model.playerName {
                Text(name)
                    .font(.headline)
                    .lineLimit(1)
            }
            Image(systemName: symbol)
                .font(.system(size: 44))
                .foregroundStyle(color)
                .contentTransition(.symbolEffect(.replace))
            Text(caption)
                .font(.caption)
                .multilineTextAlignment(.center)
            Text("Rzuty: \(model.throwCount)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
            if !model.isReachable {
                Label("Brak telefonu", systemImage: "iphone.slash")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
            Button("Zakończ", role: .destructive) { model.stopSession() }
                .font(.caption2)
                .buttonStyle(.borderless)
        }
        .animation(.default, value: model.gesturePhase)
    }

    private var symbol: String {
        switch model.gesturePhase {
        case .idle: "hand.raised"
        case .ready: "scope"
        case .windup, .active: "bolt.fill"
        case .cooldown: "checkmark.circle.fill"
        }
    }

    private var color: Color {
        switch model.gesturePhase {
        case .idle: .secondary
        case .ready: .green
        case .windup, .active: .yellow
        case .cooldown: .blue
        }
    }

    private var caption: String {
        switch model.gesturePhase {
        case .idle: "Zatrzymaj rękę w pozycji do rzutu"
        case .ready: "Gotowy, rzucaj"
        case .windup, .active: "Rzut…"
        case .cooldown: "Rzucone"
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
                    Task { await model.startSession(kind: .flick) }
                } label: {
                    Label("Rzutki (test)", systemImage: "target")
                        .frame(maxWidth: .infinity)
                }

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
