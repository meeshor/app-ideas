import Foundation

/// Wariant gry w rzutki wybrany do meczu.
public enum DartsGame: Sendable, Hashable, Codable {
    case x01(X01Rules)
    case cricket(CricketRules)
    case aroundTheClock(AroundTheClockRules)

    public var name: String {
        switch self {
        case .x01(let rules): rules.name
        case .cricket(let rules): rules.name
        case .aroundTheClock(let rules): rules.name
        }
    }

    public var throwsPerTurn: Int {
        switch self {
        case .x01(let rules): rules.throwsPerTurn
        case .cricket(let rules): rules.throwsPerTurn
        case .aroundTheClock(let rules): rules.throwsPerTurn
        }
    }

    public func start(players: [PlayerID]) -> DartsGameState {
        switch self {
        case .x01(let rules): .x01(rules.start(players: players))
        case .cricket(let rules): .cricket(rules.start(players: players))
        case .aroundTheClock(let rules): .aroundTheClock(rules.start(players: players))
        }
    }

    public func apply(_ hit: DartHit, to state: DartsGameState) -> RulesStep<DartsGameState> {
        switch (self, state) {
        case (.x01(let rules), .x01(let s)):
            let step = rules.apply(hit, to: s)
            return RulesStep(state: .x01(step.state), notices: step.notices)
        case (.cricket(let rules), .cricket(let s)):
            let step = rules.apply(hit, to: s)
            return RulesStep(state: .cricket(step.state), notices: step.notices)
        case (.aroundTheClock(let rules), .aroundTheClock(let s)):
            let step = rules.apply(hit, to: s)
            return RulesStep(state: .aroundTheClock(step.state), notices: step.notices)
        default:
            preconditionFailure("Stan nie pasuje do wariantu gry")
        }
    }
}

/// Stan meczu dowolnego wariantu plus wspólne akcesory dla UI.
public enum DartsGameState: Sendable, Hashable, Codable {
    case x01(X01State)
    case cricket(CricketState)
    case aroundTheClock(AroundTheClockState)

    public var turn: TurnOrder {
        switch self {
        case .x01(let s): s.turn
        case .cricket(let s): s.turn
        case .aroundTheClock(let s): s.turn
        }
    }

    public var winner: PlayerID? {
        switch self {
        case .x01(let s): s.winner
        case .cricket(let s): s.winner
        case .aroundTheClock(let s): s.winner
        }
    }

    public var dartsThisTurn: [DartHit] {
        switch self {
        case .x01(let s): s.dartsThisTurn
        case .cricket(let s): s.dartsThisTurn
        case .aroundTheClock(let s): s.dartsThisTurn
        }
    }

    public var dartsThrown: [Int] {
        switch self {
        case .x01(let s): s.dartsThrown
        case .cricket(let s): s.dartsThrown
        case .aroundTheClock(let s): s.dartsThrown
        }
    }

    public var players: [PlayerID] {
        switch self {
        case .x01(let s): s.players
        case .cricket(let s): s.players
        case .aroundTheClock(let s): s.players
        }
    }

    public var x01: X01State? {
        if case .x01(let s) = self { return s }
        return nil
    }

    public var cricket: CricketState? {
        if case .cricket(let s) = self { return s }
        return nil
    }

    public var aroundTheClock: AroundTheClockState? {
        if case .aroundTheClock(let s) = self { return s }
        return nil
    }
}
