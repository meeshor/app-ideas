import ArenaCore
import SwiftUI
import WristKit

/// Ekran meczu na telefonie: wyniki, tarcza, ostatni rzut, podpowiedzi, przekazanie zegarka.
/// Gdy podłączony jest TV, telefon zostaje „panelem kontrolnym” (mniejsza tarcza, te same przyciski).
struct DartsGameView: View {
    let model: DartsGameModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingHitPicker = false
    private let tv = ActiveGame.shared

    private var match: DartsMatch { model.match }

    var body: some View {
        VStack(spacing: 12) {
            DartsScoreboard(match: match)
                .padding(.horizontal)
            turnInfo
            if let cricket = match.state.cricket {
                CricketTable(state: cricket, players: match.players)
                    .padding(.horizontal)
            }
            DartboardView(
                landings: DartsBoardContent.landings(in: match),
                highlight: model.lastLanding,
                highlightedNumbers: DartsBoardContent.highlights(in: match),
                onTap: tapHandler
            )
            .frame(maxHeight: tv.isTVConnected ? 220 : .infinity)
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
        .sheet(isPresented: $showingHitPicker) {
            HitPickerView { model.enter($0) }
        }
        .onDisappear { model.stop() }
    }

    private var tapHandler: (@MainActor (BoardPoint) -> Void)? {
        guard model.input == .touch else { return nil }
        return { [model] point in model.tap(at: point) }
    }

    // MARK: - Sekcje

    private var turnInfo: some View {
        VStack(spacing: 4) {
            HStack {
                let dart = match.state.dartsThisTurn.count + 1
                Text("\(match.currentPlayer.name) · rzutka \(dart)/\(match.game.throwsPerTurn) · runda \(match.round)")
                    .font(.subheadline)
                Spacer()
                if model.input == .watch {
                    WatchPhaseLabel(phase: model.gesturePhase, reachable: model.isWatchReachable)
                }
            }
            HStack {
                Text(model.banner ?? " ")
                    .font(.title3.weight(.semibold))
                Spacer()
                if let hint = DartsBoardContent.hint(in: match) {
                    Text(hint)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
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
                Button {
                    showingHitPicker = true
                } label: {
                    Label("Wpisz trafienie", systemImage: "number")
                }
                Button {
                    model.simulateThrow()
                } label: {
                    Label("Symuluj rzut", systemImage: "wand.and.stars")
                }
            } label: {
                Label("Rzut", systemImage: "plus.circle")
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
            if let status = DartsBoardContent.status(of: player, in: match) {
                Text(status)
                    .font(.title2.monospacedDigit())
            }
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
            MatchSummaryView(match: match)
            HStack {
                Button("Cofnij") { model.undo() }
                    .buttonStyle(.bordered)
                Button("Rewanż") { model.rematch() }
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

/// Co narysować i podpowiedzieć dla bieżącego stanu meczu (wspólne dla telefonu i TV).
@MainActor
enum DartsBoardContent {
    /// Rzutki bieżącej tury; przy przekazaniu zegarka jeszcze poprzednia tura.
    static func landings(in match: DartsMatch) -> [DartLanding] {
        match.landings.isEmpty ? match.previousTurnLandings : match.landings
    }

    /// Around the Clock: bieżący cel. Cricket: pola, które bieżący gracz ma jeszcze otwarte.
    static func highlights(in match: DartsMatch) -> Set<Int> {
        guard !match.isFinished else { return [] }
        switch match.state {
        case .x01:
            return []
        case .cricket(let s):
            let index = match.currentIndex
            let open = CricketRules.targets.indices.filter { !s.isClosed(player: index, target: $0) }
            return Set(open.map { CricketRules.targets[$0] })
        case .aroundTheClock:
            return match.clockTarget(for: match.currentPlayer).map { [$0] } ?? []
        }
    }

    static func hint(in match: DartsMatch) -> String? {
        if let checkout = match.checkoutHint {
            return "Zamknięcie: \(DartsGameModel.describe(checkout))"
        }
        if let target = match.clockTarget(for: match.currentPlayer), !match.isFinished {
            return "Cel: \(target == 25 ? "środek" : "\(target)")"
        }
        return nil
    }

    /// Krótki stan gracza na ekran przekazania.
    static func status(of player: PlayerProfile, in match: DartsMatch) -> String? {
        if let remaining = match.remaining(for: player) {
            return "Zostało \(remaining)"
        }
        if let target = match.clockTarget(for: player) {
            return "Cel: \(target == 25 ? "środek" : "\(target)")"
        }
        if let s = match.state.cricket, let index = match.index(of: player) {
            return "\(s.points[index]) pkt · zamknięte \(s.closedCount(player: index))/\(CricketRules.targets.count)"
        }
        return nil
    }
}

/// Faza gestu z zegarka jako etykieta.
struct WatchPhaseLabel: View {
    let phase: GesturePhase
    let reachable: Bool

    var body: some View {
        let (text, color): (String, Color) = switch phase {
        case .idle: ("Zatrzymaj rękę", .secondary)
        case .ready: ("Gotowy", .green)
        case .windup, .active: ("Rzut…", .yellow)
        case .cooldown: ("Rzucone", .blue)
        }
        Label(reachable ? text : "Brak zegarka", systemImage: "applewatch")
            .font(.caption)
            .foregroundStyle(reachable ? color : .orange)
    }
}

/// Podsumowanie meczu: najważniejsze statystyki każdego gracza.
struct MatchSummaryView: View {
    let match: DartsMatch

    var body: some View {
        let stats = match.stats
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
            ForEach(Array(match.players.enumerated()), id: \.element.id) { index, player in
                GridRow {
                    Text(player.name).bold()
                    Text(Self.line(for: stats[index], game: match.game))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    static func line(for stats: PlayerMatchStats, game: DartsGame) -> String {
        var parts: [String] = []
        switch game {
        case .x01:
            if let average = stats.x01Average { parts.append("śr. \(StatFormat.decimal(average))") }
            if stats.bestTurn > 0 { parts.append("max \(stats.bestTurn)") }
            if let checkout = stats.checkout { parts.append("zamknięcie \(checkout)") }
        case .cricket:
            if let mpr = stats.marksPerRound { parts.append("MPR \(StatFormat.decimal(mpr))") }
        case .aroundTheClock:
            if stats.clockDarts > 0 { parts.append("\(stats.clockHits)/\(stats.clockDarts) celnych") }
        }
        parts.append("\(stats.darts) rzutek")
        return parts.joined(separator: " · ")
    }
}
