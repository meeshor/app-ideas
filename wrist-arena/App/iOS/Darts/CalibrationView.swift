import SwiftUI
import WristKit

/// „Trzy rzuty w środek”: ustala indywidualne przesunięcie kierunku gracza.
struct CalibrationView: View {
    @State private var model: CalibrationModel
    @Environment(\.dismiss) private var dismiss
    private let onSave: @MainActor (PlayerProfile) -> Void

    init(profile: PlayerProfile, onSave: @escaping @MainActor (PlayerProfile) -> Void) {
        _model = State(initialValue: CalibrationModel(profile: profile))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                let hand = model.profile.wrist == .left ? "lewą" : "prawą"
                Text("Załóż zegarek na \(hand) rękę, stań przodem do ekranu i rzuć, celując w środek tarczy.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: 16) {
                    ForEach(0..<model.required, id: \.self) { index in
                        Image(systemName: index < model.thrown || model.isDone ? "target" : "circle.dashed")
                            .font(.system(size: 40))
                            .foregroundStyle(index < model.thrown || model.isDone ? Color.accentColor : .secondary)
                    }
                }

                Text(model.message)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if model.isDone {
                    Button("Zapisz") {
                        if let profile = model.calibratedProfile { onSave(profile) }
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }

                Spacer()

                HStack {
                    Button("Od nowa") { model.restart() }
                    Spacer()
                    Button("Symulowany rzut") { model.simulateThrow() }
                        .disabled(model.isDone)
                }
                .padding(.horizontal)
            }
            .padding(.top, 32)
            .navigationTitle("Kalibracja: \(model.profile.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { dismiss() }
                }
            }
            .onAppear { model.start() }
            .onDisappear { model.stop() }
        }
    }
}
