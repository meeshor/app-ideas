import ArenaCore
import SwiftUI
import WristKit

/// Ekran meczu: wyniki, tarcza, ostatni rzut, podpowiedź zamknięcia, przekazanie zegarka.
struct DartsGameView: View {
    let model: DartsGameModel
    @Environment(\.dismiss) private var dismiss

    private var match: DartsMatch { model.match }

    var body: some View {
        VStack(spacing: 12) {
            scoreboard
            turnInfo
            DartboardView(
                landings: boardLandings,
                highlight: model.lastLanding,
                onTap: tapHandler
            )
            .padding(.horizontal)
            .animation(.spring(duration: 0.3), value: model.lastLanding)
            controls
        }
        .padding(.vertical)
        .overlay {
            if match.isFinished {
                finishedCard
            } else if model.awaitingHandoff {
                handoffCard
            }
        }
        .onDisappear { model.stop() }
    }

    private var tapHandler: (@MainActor (BoardPoint) -> Void)? {
        guard model.input == .touch else { return nil }
        return { [model] point in model.tap(at: point) }
    }

    /// Rzutki bieżącej tury; przy przekazaniu zegarka pokazujemy jeszcze poprzednią turę.
    private var boardLandings: [DartLanding] {
        match.landings.isEmpty ? match.previousTurnLandings : match.landings
    }

    // MARK: - Sekcje

    private var scoreboard: some View {
        HStack(spacing: 8) {
            ForEach(Array(match.players.enumerated()), id: \.element.id) { index, player in
                let isCurrent = index == match.state.turn.currentIndex && !match.isFinished
                VStack(spacing: 2) {
                    Text(player.name)
                        .font(.caption)
                        .lineLimit(1)
                    Text("\(match.remaining(for: player))")
                        .font(.system(.title, design: .rounded, weight: .bold).monospacedDigit())
                    if let average = match.state.threeDartAverage(for: player.id) {
                        Text("śr. \(average, format: .number.precision(.fractionLength(1)))")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    } else {
                        Text(" ").font(.caption2)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isCurrent ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrent ? Color.accentColor : .clear, lineWidth: 2)
                )
            }
        }
        .padding(.horizontal)
    }

    private var turnInfo: some View {
        VStack(spacing: 4) {
            HStack {
                Text("\(match.currentPlayer.name) · rzutka \(match.state.dartsThisTurn.count + 1)/\(match.rules.throwsPerTurn)")
                    .font(.subheadline)
                Spacer()
                if model.input == .watch {
                    watchPhase
                }
            }
            HStack {
                Text(model.banner ?? " ")
                    .font(.title3.weight(.semibold))
                Spacer()
                if let hint = match.checkoutHint {
                    Text("Zamknięcie: \(DartsGameModel.describe(hint))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }

    private var watchPhase: some View {
        let (text, color): (String, Color) = switch model.gesturePhase {
        case .idle: ("Zatrzymaj rękę", .secondary)
        case .ready: ("Gotowy", .green)
        case .windup, .active: ("Rzut…", .yellow)
        case .cooldown: ("Rzucone", .blue)
        }
        return Label(model.isWatchReachable ? text : "Brak zegarka", systemImage: "applewatch")
            .font(.caption)
            .foregroundStyle(model.isWatchReachable ? color : .orange)
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
            Button {
                model.simulateThrow()
            } label: {
                Label("Symuluj rzut", systemImage: "wand.and.stars")
            }
            .disabled(model.awaitingHandoff || match.isFinished)
        }
        .buttonStyle(.bordered)
        .padding(.horizontal)
    }

    // MARK: - Nakładki

    private var handoffCard: some View {
        let player = match.currentPlayer
        return VStack(spacing: 16) {
            if let banner = model.banner {
                Text(banner).font(.headline).foregroundStyle(.secondary)
            }
            Text("Kolej: \(player.name)")
                .font(.largeTitle.bold())
            if model.input == .watch {
                Label(
                    "Załóż zegarek na \(player.wrist == .left ? "lewą" : "prawą") rękę i zapnij pasek",
                    systemImage: "applewatch"
                )
                .multilineTextAlignment(.center)
            }
            Text("Zostało \(match.remaining(for: player))")
                .font(.title2.monospacedDigit())
            Button("Gotowe, rzucam") { model.confirmHandoff() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            if match.canUndo {
                Button("Cofnij ostatnią rzutkę") { model.undo() }
                    .font(.footnote)
            }
        }
        .padding(28)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        .padding()
    }

    private var finishedCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 56))
                .foregroundStyle(.yellow)
            Text("\(match.winner?.name ?? "?") wygrywa!")
                .font(.largeTitle.bold())
            ForEach(match.players) { player in
                if let average = match.state.threeDartAverage(for: player.id) {
                    Text("\(player.name): średnia \(average, format: .number.precision(.fractionLength(1)))")
                        .font(.subheadline.monospacedDigit())
                }
            }
            HStack {
                Button("Cofnij") { model.undo() }
                    .buttonStyle(.bordered)
                Button("Koniec") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(28)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        .padding()
    }
}
