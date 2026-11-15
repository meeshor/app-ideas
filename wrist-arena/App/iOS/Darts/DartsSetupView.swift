import ArenaCore
import SwiftUI
import WristKit

/// Wariant wybierany na ekranie konfiguracji.
enum DartsVariant: String, CaseIterable, Identifiable {
    case x01
    case cricket
    case aroundTheClock

    var id: String { rawValue }

    var title: String {
        switch self {
        case .x01: "X01"
        case .cricket: "Cricket"
        case .aroundTheClock: "Dookoła"
        }
    }
}

/// Konfiguracja meczu: gracze (1–4, pass & play), wariant, wejście, kalibracja, statystyki.
struct DartsSetupView: View {
    @State private var store = PlayerStore()
    @State private var variant: DartsVariant = .x01
    @State private var startScore = 501
    @State private var doubleOut = true
    @State private var cutThroat = false
    @State private var finishOnBull = true
    @State private var fastClock = false
    @State private var input: DartsInput = .watch
    @State private var game: DartsGameModel?
    @State private var calibrating: PlayerProfile?
    @State private var error: String?

    private let link = PhoneLink.shared
    private let maxPlayers = ModuleCatalog.darts.playerRange.upperBound

    var body: some View {
        Form {
            playersSection
            gameSection

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
            } footer: {
                Text("Na TV: włącz Duplikowanie ekranu (AirPlay). Telefon zostaje panelem, a TV pokazuje tarczę.")
            }
        }
        .navigationTitle("Rzutki")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink {
                    PlayerStatsView(store: store)
                } label: {
                    Label("Statystyki", systemImage: "chart.bar")
                }
            }
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
        }
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

    private var playersSection: some View {
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
    }

    private var gameSection: some View {
        Section("Gra") {
            Picker("Wariant", selection: $variant) {
                ForEach(DartsVariant.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            switch variant {
            case .x01:
                Picker("Start", selection: $startScore) {
                    ForEach([301, 501, 701], id: \.self) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.segmented)
                Toggle("Double-out (koniec na podwójnym)", isOn: $doubleOut)
            case .cricket:
                Toggle("Cut-throat (punkty dla rywali)", isOn: $cutThroat)
                Text("Zamknij 15–20 i środek (3 znaki). Dodatkowe znaki na zamkniętym polu dają punkty. Limit 20 rund.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .aroundTheClock:
                Toggle("Na koniec środek", isOn: $finishOnBull)
                Toggle("Podwójne/potrójne przeskakują dalej", isOn: $fastClock)
            }
            Picker("Rzuty", selection: $input) {
                ForEach(DartsInput.allCases) { Text($0.title).tag($0) }
            }
        }
    }

    private var selectedGame: DartsGame {
        switch variant {
        case .x01: .x01(X01Rules(startScore: startScore, doubleOut: doubleOut))
        case .cricket: .cricket(CricketRules(cutThroat: cutThroat))
        case .aroundTheClock: .aroundTheClock(AroundTheClockRules(finishOnBull: finishOnBull, advanceByMultiplier: fastClock))
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
            let match = try DartsMatch(players: store.profiles, game: selectedGame)
            error = nil
            let model = DartsGameModel(match: match, input: input) { [store] finished in
                store.record(finished)
            }
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
