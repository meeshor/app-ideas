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

/// Mecz rzutek na telefonie: rzuty z zegarka/dotyku/symulacji → `DartsMatch`, przekazywanie zegarka.
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

    init(match: DartsMatch, input: DartsInput) {
        self.match = match
        self.input = input
    }

    var gesturePhase: GesturePhase { hub.gesturePhase }
    var isWatchReachable: Bool { hub.isReachable }

    // MARK: - Cykl życia

    func start() {
        guard input == .watch else { return }
        hub.activate()
        hub.addMessageHandler(handlerKey) { [weak self] message, _ in
            guard case .throwEvent(let event) = message.payload else { return }
            self?.receive(event)
        }
        hub.send(.control(.startSession(kind: .flick)))
    }

    func stop() {
        hub.removeMessageHandler(handlerKey)
        if input == .watch {
            hub.send(.control(.stopSession))
        }
    }

    /// Gracz ma zegarek na ręce: zaczynamy jego turę.
    func confirmHandoff() {
        awaitingHandoff = false
        banner = nil
        if input == .watch {
            let player = match.currentPlayer
            hub.send(.control(.setActivePlayer(name: player.name, wrist: player.wrist)))
        }
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

    func undo() {
        let wasHandoff = awaitingHandoff
        let before = match.currentPlayer.id
        match.undo()
        lastLanding = match.landings.last
        banner = nil
        // Cofnięcie do tury poprzedniego gracza: bez ekranu przekazania (zegarek wciąż u niego).
        if wasHandoff || before != match.currentPlayer.id {
            awaitingHandoff = false
            if input == .watch {
                let player = match.currentPlayer
                hub.send(.control(.setActivePlayer(name: player.name, wrist: player.wrist)))
            }
        }
    }

    private func show(_ landing: DartLanding, notices: [GameNotice]) {
        lastLanding = landing
        banner = Self.describe(landing.hit)
        for notice in notices {
            switch notice {
            case .bust:
                banner = "Bust! \(Self.describe(landing.hit))"
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
