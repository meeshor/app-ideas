import ArenaCore
import Foundation
import Observation
import WristKit

/// Konkurs rzutów karnych na telefonie: rzuty i zwody z zegarka, dotyk, symulacja, wybór bramkarza (pojedynek).
@MainActor
@Observable
final class HandballGameModel {
    /// Etap bieżącej próby.
    enum Stage: Equatable {
        /// Pojedynek: bramkarz w ukryciu wybiera strefę.
        case keeperChoice
        /// Kolejny rzucający bierze zegarek.
        case handoff
        /// Czekamy na rzut (zwody się liczą).
        case shooting
    }

    private(set) var match: HandballMatch
    let input: DartsInput
    private(set) var stage: Stage
    private(set) var lastAttempt: HandballAttempt?
    private(set) var banner: String?

    @ObservationIgnored private let hub = PhoneLink.shared
    @ObservationIgnored private let handlerKey = "handball"

    init(match: HandballMatch, input: DartsInput) {
        self.match = match
        self.input = input
        self.stage = Self.firstStage(for: match)
    }

    var gesturePhase: GesturePhase { hub.gesturePhase }
    var isWatchReachable: Bool { hub.isReachable }

    // MARK: - Cykl życia

    func start() {
        ActiveGame.shared.handball = self
        guard input == .watch else { return }
        hub.activate()
        hub.addMessageHandler(handlerKey) { [weak self] message, _ in
            guard case .throwEvent(let event) = message.payload else { return }
            self?.receive(event)
        }
        hub.send(.control(.updateTuning(TuningStore.shared.gesture)))
        hub.send(.control(.startSession(kind: .overarm)))
    }

    func stop() {
        hub.removeMessageHandler(handlerKey)
        if ActiveGame.shared.handball === self {
            ActiveGame.shared.handball = nil
        }
        if input == .watch {
            hub.send(.control(.stopSession))
        }
    }

    func chooseKeeper(_ zone: GoalZone) {
        guard stage == .keeperChoice else { return }
        match.chooseKeeperZone(zone)
        stage = match.players.count == 1 ? .shooting : .handoff
    }

    func confirmHandoff() {
        stage = .shooting
        banner = nil
        if input == .watch {
            let shooter = match.currentShooter
            hub.send(.control(.setActivePlayer(name: shooter.name, wrist: shooter.wrist)))
        }
    }

    func rematch() {
        let rotated = Array(match.players.dropFirst()) + match.players.prefix(1)
        guard let next = try? HandballMatch(players: rotated, mode: match.mode, shotsPerPlayer: match.shotsPerPlayer, model: match.model)
        else { return }
        match = next
        lastAttempt = nil
        banner = nil
        stage = Self.firstStage(for: next)
    }

    // MARK: - Rzuty

    func receive(_ event: ThrowEvent) {
        guard stage == .shooting, !match.isFinished else { return }
        if event.isFeint {
            match.registerFeint()
            banner = match.pendingFeints == 1 ? "Zwód!" : "Zwód ×\(match.pendingFeints)!"
            return
        }
        if let attempt = match.shoot(event) { show(attempt) }
    }

    func tap(at point: GoalPoint) {
        guard input == .touch, stage == .shooting, !match.isFinished else { return }
        if let attempt = match.shoot(aimingAt: point) { show(attempt) }
    }

    func simulate(feints: Int = 0) {
        guard stage == .shooting, !match.isFinished else { return }
        let tuning = TuningStore.shared.gesture.overarm
        for event in ThrowSimulator.overarmEvents(wrist: match.currentShooter.wrist, feints: feints, tuning: tuning) {
            receive(event)
        }
    }

    func undo() {
        match.undo()
        lastAttempt = match.attempts.last
        banner = nil
        stage = match.needsKeeperChoice ? .keeperChoice : .shooting
    }

    // MARK: - Pomocnicze

    private func show(_ attempt: HandballAttempt) {
        lastAttempt = attempt
        let speed = Int(attempt.shot.speedKmh.rounded())
        var text = "\(Self.describe(attempt.outcome)) · \(speed) km/h"
        if attempt.keeperAction.fooledByFeint { text += " · bramkarz kupił zwód" }
        if let winner = match.winner {
            let name = match.players.first { $0.id == winner }?.name ?? "?"
            text = "\(Self.describe(attempt.outcome)) · \(name) wygrywa!"
        }
        banner = text
        guard !match.isFinished else { return }
        if match.mode == .duel {
            stage = .keeperChoice
        } else {
            stage = match.players.count == 1 ? .shooting : .handoff
        }
    }

    private static func firstStage(for match: HandballMatch) -> Stage {
        if match.mode == .duel { return .keeperChoice }
        return match.players.count == 1 ? .shooting : .handoff
    }

    static func describe(_ outcome: ShotOutcome) -> String {
        switch outcome {
        case .goal: "GOL!"
        case .saved: "Obronione"
        case .post: "Słupek!"
        case .miss: "Obok bramki"
        }
    }
}

extension HandballGameModel: Identifiable {}
