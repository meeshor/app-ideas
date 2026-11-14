import ArenaCore
import Foundation
import Observation
import WristKit

/// Skąd biorą się rzuty w meczu rzutek.
enum DartsInput: String, CaseIterable, Identifiable {
    case watch
    case touch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .watch: "Zegarek"
        case .touch: "Dotyk"
        }
    }
}

/// Mecz rzutek na telefonie: rzuty z zegarka/dotyku/symulacji → `DartsMatch`, przekazywanie zegarka,
/// rewanż i zapis statystyk. Ten sam obiekt czyta ekran TV (`ActiveGame`).
@MainActor
@Observable
final class DartsGameModel {
    private(set) var match: DartsMatch
    let input: DartsInput
    /// Czekamy, aż kolejny gracz weźmie zegarek (ekran „Podaj zegarek”).
    private(set) var awaitingHandoff = true
    /// Ostatnia rzutka (z animacją).
    private(set) var lastLanding: DartLanding?
    private(set) var banner: String?

    @ObservationIgnored private let hub = PhoneLink.shared
    @ObservationIgnored private let handlerKey = "darts"
    @ObservationIgnored private let onFinish: @MainActor (DartsMatch) -> Void
    @ObservationIgnored private var statsRecorded = false

    init(match: DartsMatch, input: DartsInput, onFinish: @escaping @MainActor (DartsMatch) -> Void = { _ in }) {
        self.match = match
        self.input = input
        self.onFinish = onFinish
    }

    var gesturePhase: GesturePhase { hub.gesturePhase }
    var isWatchReachable: Bool { hub.isReachable }

    // MARK: - Cykl życia

    func start() {
        ActiveGame.shared.current = self
        guard input == .watch else { return }
        hub.activate()
        hub.addMessageHandler(handlerKey) { [weak self] message, _ in
            guard case .throwEvent(let event) = message.payload else { return }
            self?.receive(event)
        }
        hub.send(.control(.startSession(kind: .flick)))
    }

    /// Wyjście z meczu: zapis statystyk (jeśli skończony), koniec sesji na zegarku.
    func stop() {
        recordStatsIfNeeded()
        hub.removeMessageHandler(handlerKey)
        if ActiveGame.shared.current === self {
            ActiveGame.shared.current = nil
        }
        if input == .watch {
            hub.send(.control(.stopSession))
        }
    }

    /// Gracz ma zegarek na ręce: zaczynamy jego turę.
    func confirmHandoff() {
        awaitingHandoff = false
        banner = nil
        sendActivePlayer()
    }

    func rematch() {
        recordStatsIfNeeded()
        guard let next = try? match.rematch() else { return }
        match = next
        statsRecorded = false
        lastLanding = nil
        banner = nil
        awaitingHandoff = true
    }

    // MARK: - Rzuty

    func receive(_ event: ThrowEvent) {
        guard !awaitingHandoff, !match.isFinished else { return }
        let (landing, notices) = match.throwDart(event)
        show(landing, notices: notices)
    }

    func tap(at point: BoardPoint) {
        guard input == .touch, !awaitingHandoff, !match.isFinished else { return }
        let (landing, notices) = match.throwDart(aimingAt: point)
        show(landing, notices: notices)
    }

    func simulateThrow() {
        guard !awaitingHandoff, !match.isFinished else { return }
        guard let event = ThrowSimulator.throwEvent(wrist: match.currentPlayer.wrist) else {
            banner = "Symulacja nie dała rzutu"
            return
        }
        let (landing, notices) = match.throwDart(event)
        show(landing, notices: notices)
    }

    /// Ręczne wpisanie trafienia (poprawka, gdy zegarek źle rozpoznał rzut albo gra na prawdziwej tarczy).
    func enter(_ hit: DartHit) {
        guard !awaitingHandoff, !match.isFinished else { return }
        let notices = match.record(hit: hit)
        show(match.landings.last ?? match.previousTurnLandings.last, hit: hit, notices: notices)
    }

    func undo() {
        let wasHandoff = awaitingHandoff
        let before = match.currentPlayer.id
        match.undo()
        lastLanding = match.landings.last
        banner = nil
        // Cofnięcie do tury poprzedniego gracza: bez ekranu przekazania (zegarek wciąż u niego).
        if wasHandoff || before != match.currentPlayer.id {
            awaitingHandoff = false
            sendActivePlayer()
        }
    }

    // MARK: - Pomocnicze

    private func show(_ landing: DartLanding, notices: [GameNotice]) {
        show(landing, hit: landing.hit, notices: notices)
    }

    private func show(_ landing: DartLanding?, hit: DartHit, notices: [GameNotice]) {
        lastLanding = landing
        banner = Self.describe(hit)
        for notice in notices {
            switch notice {
            case .bust:
                banner = "Bust! \(Self.describe(hit))"
            case .scored(_, let points) where points > 0 && isCricket:
                banner = "\(Self.describe(hit)) · +\(points) pkt"
            case .finished(let winner):
                let name = match.players.first { $0.id == winner }?.name ?? "?"
                banner = "\(name) wygrywa!"
            case .turnEnded:
                awaitingHandoff = !match.isFinished
            case .scored, .message:
                break
            }
        }
    }

    private var isCricket: Bool {
        if case .cricket = match.game { return true }
        return false
    }

    private func sendActivePlayer() {
        guard input == .watch else { return }
        let player = match.currentPlayer
        hub.send(.control(.setActivePlayer(name: player.name, wrist: player.wrist)))
    }

    private func recordStatsIfNeeded() {
        guard match.isFinished, !statsRecorded else { return }
        statsRecorded = true
        onFinish(match)
    }

    // MARK: - Opisy

    static func describe(_ hit: DartHit) -> String {
        switch hit.ring {
        case .miss: "Pudło"
        case .single: "\(hit.number)"
        case .double: "D\(hit.number)"
        case .triple: "T\(hit.number)"
        case .outerBull: "25"
        case .innerBull: "Bull 50"
        }
    }

    static func describe(_ hits: [DartHit]) -> String {
        hits.map { describe($0) }.joined(separator: " · ")
    }
}

/// Mecz widoczny dla drugiego ekranu (TV przez AirPlay albo kabel).
@MainActor
@Observable
final class ActiveGame {
    static let shared = ActiveGame()

    var current: DartsGameModel?
    /// Czy podłączony jest zewnętrzny ekran (telefon może wtedy pokazać mniejszą tarczę).
    var isTVConnected = false

    private init() {}
}
