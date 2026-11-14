import ArenaCore
import SwiftUI
import WristKit

/// Konfiguracja meczu: gracze (2–4, pass & play), wariant X01, wejście, kalibracja.
struct DartsSetupView: View {
    @State private var store = PlayerStore()
    @State private var startScore = 501
    @State private var doubleOut = true
    @State private var input: DartsInput = .watch
    @State private var game: DartsGameModel?
    @State private var calibrating: PlayerProfile?
    @State private var error: String?

    private let link = PhoneLink.shared
    private let maxPlayers = ModuleCatalog.darts.playerRange.upperBound

    var body: some View {
        Form {
            Section {
                ForEach(store.profiles) { profile in
                    PlayerRow(profile: binding(for: profile)) {
                        calibrating = profile
                    }
                }
                .onDelete { store.remove(at: $0) }
                .onMove { store.move(from: $0, to: $1) }
                Button {
                    store.add()
                } label: {
                    Label("Dodaj gracza", systemImage: "person.badge.plus")
                }
                .disabled(store.profiles.count >= maxPlayers)
            } header: {
                Text("Gracze (\(store.profiles.count)/\(maxPlayers))")
            } footer: {
                Text("Kolejność = kolejność rzucania. Jeden zegarek przekazujecie sobie po każdej turze.")
            }

            Section("Gra") {
                Picker("Wariant", selection: $startScore) {
                    ForEach([301, 501, 701], id: \.self) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.segmented)
                Toggle("Double-out (koniec na podwójnym)", isOn: $doubleOut)
                Picker("Rzuty", selection: $input) {
                    ForEach(DartsInput.allCases) { Text($0.title).tag($0) }
                }
            }

            if input == .watch {
                Section("Zegarek") {
                    LabeledContent("Osiągalny", value: link.isReachable ? "tak" : "nie")
                    if !link.isReachable {
                        Text("Otwórz Wrist Arena na zegarku. Bez zegarka zagrasz dotykiem albo symulowanymi rzutami.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Button("Start") { start() }
                    .frame(maxWidth: .infinity)
                    .font(.headline)
                    .disabled(store.profiles.isEmpty)
                if let error {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Rzutki")
        .toolbar { EditButton() }
        .onAppear { link.activate() }
        .sheet(item: $calibrating) { profile in
            CalibrationView(profile: profile) { updated in
                store.update(updated)
            }
        }
        .fullScreenCover(item: $game) { model in
            DartsGameView(model: model)
        }
    }

    private func binding(for profile: PlayerProfile) -> Binding<PlayerProfile> {
        Binding(
            get: { store.profile(id: profile.id) ?? profile },
            set: { store.update($0) }
        )
    }

    private func start() {
        do {
            let match = try DartsMatch(
                players: store.profiles,
                rules: X01Rules(startScore: startScore, doubleOut: doubleOut)
            )
            error = nil
            let model = DartsGameModel(match: match, input: input)
            model.start()
            game = model
        } catch {
            self.error = "Nie da się zacząć: \(error)"
        }
    }
}

extension DartsGameModel: Identifiable {}

private struct PlayerRow: View {
    @Binding var profile: PlayerProfile
    var onCalibrate: @MainActor () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Imię", text: $profile.name)
                .font(.headline)
            Picker("Zegarek na", selection: $profile.wrist) {
                Text("lewej ręce").tag(WristSide.left)
                Text("prawej ręce").tag(WristSide.right)
            }
            .pickerStyle(.segmented)
            HStack {
                Picker("Poziom", selection: $profile.difficulty) {
                    Text("Łatwy").tag(Difficulty.easy)
                    Text("Normalny").tag(Difficulty.normal)
                    Text("Trudny").tag(Difficulty.hard)
                    Text("Pro").tag(Difficulty.pro)
                }
                .labelsHidden()
                Spacer()
                let calibrated = profile.calibration(for: .flick).sampleCount > 0
                Button(calibrated ? "Kalibruj ponownie" : "Kalibruj", action: onCalibrate)
                    .buttonStyle(.bordered)
                    .tint(calibrated ? Color.secondary : Color.accentColor)
            }
        }
        .padding(.vertical, 4)
    }
}
