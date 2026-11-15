import ArenaCore
import SwiftUI
import WristKit

/// Konfiguracja konkursu rzutów karnych.
struct HandballSetupView: View {
    enum ModeChoice: String, CaseIterable, Identifiable {
        case ai, duel
        var id: String { rawValue }
    }

    @State private var store = PlayerStore()
    @State private var modeChoice: ModeChoice = .ai
    @State private var keeperLevel: KeeperLevel = .regular
    @State private var shots = 5
    @State private var input: DartsInput = .watch
    @State private var game: HandballGameModel?
    @State private var calibrating: PlayerProfile?
    @State private var error: String?

    var body: some View {
        Form {
            Section {
                ForEach(store.profiles) { profile in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(profile.name).font(.headline)
                            Text(profile.wrist == .left ? "zegarek na lewej" : "zegarek na prawej")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        let calibrated = profile.calibration(for: .overarm).sampleCount > 0
                        Button(calibrated ? "Kalibruj ponownie" : "Kalibruj") { calibrating = profile }
                            .buttonStyle(.bordered)
                    }
                }
            } header: {
                Text("Gracze")
            } footer: {
                Text("Graczy, nadgarstek i poziom zmienisz w module Rzutki (wspólna lista).")
            }

            Section("Konkurs") {
                Picker("Tryb", selection: $modeChoice) {
                    Text("Przeciw AI").tag(ModeChoice.ai)
                    Text("Pojedynek (2)").tag(ModeChoice.duel)
                }
                .pickerStyle(.segmented)
                if modeChoice == .ai {
                    Picker("Bramkarz", selection: $keeperLevel) {
                        Text("Junior").tag(KeeperLevel.rookie)
                        Text("Ligowy").tag(KeeperLevel.regular)
                        Text("Reprezentant").tag(KeeperLevel.pro)
                    }
                } else {
                    Text("Bramkarz wybiera róg na telefonie, zanim rzucający weźmie zegarek. Rzucający nie patrzy!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Stepper("Rzutów na gracza: \(shots)", value: $shots, in: 1...10)
                Picker("Rzuty", selection: $input) {
                    ForEach(DartsInput.allCases) { Text($0.title).tag($0) }
                }
                Text("Zwód: zacznij zamach i zatrzymaj rękę. Bramkarz AI może się na niego rzucić.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Start") { start() }
                    .frame(maxWidth: .infinity)
                    .font(.headline)
                if let error {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Rzut karny")
        .onAppear { PhoneLink.shared.activate() }
        .sheet(item: $calibrating) { profile in
            CalibrationView(profile: profile, kind: .overarm) { updated in
                store.update(updated)
            }
        }
        .fullScreenCover(item: $game) { model in
            HandballGameView(model: model)
        }
    }

    private func start() {
        let mode: HandballMode = modeChoice == .ai ? .versusAI(keeperLevel) : .duel
        let players = modeChoice == .duel ? Array(store.profiles.prefix(2)) : Array(store.profiles.prefix(4))
        do {
            let match = try HandballMatch(players: players, mode: mode, shotsPerPlayer: shots)
            error = nil
            let model = HandballGameModel(match: match, input: input)
            model.start()
            game = model
        } catch {
            self.error = modeChoice == .duel ? "Pojedynek wymaga 2 graczy." : "Nie da się zacząć: \(error)"
        }
    }
}

/// Ekran konkursu na telefonie.
struct HandballGameView: View {
    let model: HandballGameModel
    @Environment(\.dismiss) private var dismiss

    private var match: HandballMatch { model.match }

    var body: some View {
        VStack(spacing: 12) {
            HandballScoreboard(match: match)
                .padding(.horizontal)
            HStack {
                Text(statusLine)
                    .font(.subheadline)
                Spacer()
                if model.input == .watch {
                    WatchPhaseLabel(phase: model.gesturePhase, reachable: model.isWatchReachable)
                }
            }
            .padding(.horizontal)
            Text(model.banner ?? " ")
                .font(.title2.weight(.bold))
            GoalView(attempt: model.lastAttempt, onTap: tapHandler)
                .padding(.horizontal)
            Spacer(minLength: 0)
            controls
        }
        .padding(.vertical)
        .overlay { overlay }
        .onDisappear { model.stop() }
    }

    private var statusLine: String {
        let phase = match.isSuddenDeath ? "dogrywka" : "rzut \(match.round)/\(match.shotsPerPlayer)"
        return "\(match.currentShooter.name) · \(phase)"
    }

    private var tapHandler: (@MainActor (GoalPoint) -> Void)? {
        guard model.input == .touch else { return nil }
        return { [model] point in model.tap(at: point) }
    }

    private var controls: some View {
        HStack {
            Button("Zakończ", role: .destructive) { dismiss() }
            Spacer()
            Button {
                model.undo()
            } label: {
                Label("Cofnij", systemImage: "arrow.uturn.backward")
            }
            .disabled(!match.canUndo)
            Spacer()
            Menu {
                Button("Symuluj rzut") { model.simulate() }
                Button("Symuluj zwód i rzut") { model.simulate(feints: 1) }
            } label: {
                Label("Rzut", systemImage: "wand.and.stars")
            }
            .disabled(model.stage != .shooting || match.isFinished)
        }
        .buttonStyle(.bordered)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var overlay: some View {
        if match.isFinished {
            card {
                Image(systemName: "trophy.fill").font(.system(size: 56)).foregroundStyle(.yellow)
                Text("\(match.players.first { $0.id == match.winner }?.name ?? "?") wygrywa!")
                    .font(.largeTitle.bold())
                ForEach(match.players) { player in
                    Text("\(player.name): \(match.goals(for: player))/\(match.attempts(for: player).count)")
                        .font(.title3.monospacedDigit())
                }
                HStack {
                    Button("Cofnij") { model.undo() }.buttonStyle(.bordered)
                    Button("Rewanż") { model.rematch() }.buttonStyle(.bordered)
                    Button("Koniec") { dismiss() }.buttonStyle(.borderedProminent)
                }
            }
        } else if model.stage == .keeperChoice, let keeper = match.currentKeeper {
            card {
                Text("Bramkarz: \(keeper.name)").font(.title.bold())
                Text("\(match.currentShooter.name), nie patrz! Wybierz, gdzie się rzucisz.")
                    .multilineTextAlignment(.center)
                KeeperZonePicker { model.chooseKeeper($0) }
            }
        } else if model.stage == .handoff {
            card {
                if let banner = model.banner {
                    Text(banner).font(.headline).foregroundStyle(.secondary)
                }
                Text("Rzuca: \(match.currentShooter.name)").font(.largeTitle.bold())
                if model.input == .watch {
                    Label(
                        "Załóż zegarek na \(match.currentShooter.wrist == .left ? "lewą" : "prawą") rękę i zapnij pasek",
                        systemImage: "applewatch"
                    )
                    .multilineTextAlignment(.center)
                }
                Text("Gole: \(match.goals(for: match.currentShooter))").font(.title2.monospacedDigit())
                Button("Gotowe, rzucam") { model.confirmHandoff() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 16, content: content)
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding()
    }
}

/// Wybór strefy 3 × 3 przez bramkarza (wiersz górny na górze).
struct KeeperZonePicker: View {
    var onPick: @MainActor (GoalZone) -> Void

    var body: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach((0..<3).reversed(), id: \.self) { row in
                GridRow {
                    ForEach(0..<3, id: \.self) { column in
                        let zone = GoalZone(column: column, row: row)
                        Button {
                            onPick(zone)
                        } label: {
                            Text(zone.name)
                                .font(.caption)
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }
}

/// Wyniki: gole i kropki prób każdego gracza.
struct HandballScoreboard: View {
    let match: HandballMatch
    var large = false

    var body: some View {
        HStack(spacing: large ? 16 : 8) {
            ForEach(Array(match.players.enumerated()), id: \.element.id) { index, player in
                let isCurrent = index == match.currentIndex && !match.isFinished
                VStack(spacing: 4) {
                    Text(player.name).font(large ? .title2 : .caption).lineLimit(1)
                    Text("\(match.goals(for: player))")
                        .font(.system(large ? .largeTitle : .title, design: .rounded, weight: .bold).monospacedDigit())
                    HStack(spacing: 3) {
                        ForEach(Array(match.attempts(for: player).enumerated()), id: \.offset) { _, attempt in
                            Circle()
                                .fill(attempt.outcome.isGoal ? Color.green : Color.red)
                                .frame(width: large ? 14 : 8, height: large ? 14 : 8)
                        }
                    }
                    .frame(minHeight: large ? 14 : 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, large ? 16 : 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isCurrent ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08))
                )
            }
        }
    }
}

/// Konkurs na TV.
struct TVHandballView: View {
    let model: HandballGameModel

    var body: some View {
        HStack(spacing: 48) {
            GoalView(attempt: model.lastAttempt, showZones: false)
            VStack(alignment: .leading, spacing: 24) {
                Text("Rzut karny").font(.title2).foregroundStyle(.secondary)
                HandballScoreboard(match: model.match, large: true)
                Spacer()
                Text(model.banner ?? "Rzuca: \(model.match.currentShooter.name)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                if model.stage == .keeperChoice, let keeper = model.match.currentKeeper {
                    Text("\(keeper.name) wybiera róg…").font(.title2).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: 640)
        }
        .padding(48)
        .foregroundStyle(.white)
    }
}
