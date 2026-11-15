import ArenaCore
import SwiftUI
import UIKit

/// Delegat aplikacji: osobna scena dla zewnętrznego ekranu (TV przez AirPlay albo kabel).
/// Pozostałe sceny dostają konfigurację domyślną (SwiftUI).
@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        guard connectingSceneSession.role == .windowExternalDisplayNonInteractive else {
            return connectingSceneSession.configuration
        }
        let configuration = UISceneConfiguration(name: "TV", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = ExternalDisplaySceneDelegate.self
        return configuration
    }
}

/// Scena na TV: obraz gry bez interakcji (sterowanie zostaje na telefonie i zegarku).
@MainActor
final class ExternalDisplaySceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: TVRootView(active: ActiveGame.shared))
        window.isHidden = false
        self.window = window
        ActiveGame.shared.isTVConnected = true
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        window = nil
        ActiveGame.shared.isTVConnected = false
    }
}

/// Zawartość ekranu TV: mecz albo ekran powitalny.
struct TVRootView: View {
    let active: ActiveGame

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let game = active.current {
                TVGameView(model: game)
            } else if let handball = active.handball {
                TVHandballView(model: handball)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "applewatch.radiowaves.left.and.right")
                        .font(.system(size: 96))
                    Text("Wrist Arena")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                    Text("Wybierz grę na telefonie")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.white)
            }
        }
        .preferredColorScheme(.dark)
    }
}

/// Mecz na dużym ekranie: tarcza po lewej, wyniki i stan tury po prawej.
struct TVGameView: View {
    let model: DartsGameModel

    private var match: DartsMatch { model.match }

    var body: some View {
        HStack(spacing: 48) {
            DartboardView(
                landings: DartsBoardContent.landings(in: match),
                highlight: model.lastLanding,
                highlightedNumbers: DartsBoardContent.highlights(in: match)
            )
            .animation(.spring(duration: 0.3), value: model.lastLanding)

            VStack(alignment: .leading, spacing: 24) {
                Text(match.game.name)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                DartsScoreboard(match: match, large: true)
                if let cricket = match.state.cricket {
                    CricketTable(state: cricket, players: match.players, large: true)
                }
                Spacer()
                status
            }
            .frame(maxWidth: 640)
        }
        .padding(48)
        .foregroundStyle(.white)
    }

    @ViewBuilder
    private var status: some View {
        if let winner = match.winner {
            VStack(alignment: .leading, spacing: 12) {
                Label("\(winner.name) wygrywa!", systemImage: "trophy.fill")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.yellow)
                MatchSummaryView(match: match)
                    .font(.title3)
            }
        } else if model.awaitingHandoff {
            VStack(alignment: .leading, spacing: 8) {
                Text("Kolej: \(match.currentPlayer.name)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                Text("Weź zegarek i potwierdź na telefonie")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text(model.banner ?? "\(match.currentPlayer.name) rzuca")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .contentTransition(.opacity)
                HStack(spacing: 16) {
                    let dart = match.state.dartsThisTurn.count + 1
                    Text("Rzutka \(min(dart, match.game.throwsPerTurn))/\(match.game.throwsPerTurn)")
                    if let hint = DartsBoardContent.hint(in: match) {
                        Text(hint)
                    }
                    if model.input == .watch {
                        WatchPhaseLabel(phase: model.gesturePhase, reachable: model.isWatchReachable)
                            .font(.title3)
                    }
                }
                .font(.title2.monospacedDigit())
                .foregroundStyle(.secondary)
            }
        }
    }
}
