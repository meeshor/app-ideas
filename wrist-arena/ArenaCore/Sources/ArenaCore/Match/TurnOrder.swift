import Foundation

/// Kolejka graczy w trybie pass & play: kto rzuca i który to rzut w turze.
public struct TurnOrder: Sendable, Hashable, Codable {
    public private(set) var players: [PlayerID]
    public private(set) var currentIndex: Int = 0
    public private(set) var throwInTurn: Int = 0
    public private(set) var round: Int = 1
    public var throwsPerTurn: Int

    public init(players: [PlayerID], throwsPerTurn: Int = 3) {
        precondition(!players.isEmpty, "Potrzebny co najmniej jeden gracz")
        self.players = players
        self.throwsPerTurn = throwsPerTurn
    }

    public var current: PlayerID { players[currentIndex] }

    /// Zalicza rzut. Zwraca `true`, gdy tura się skończyła i kolej przeszła dalej.
    @discardableResult
    public mutating func recordThrow() -> Bool {
        throwInTurn += 1
        guard throwInTurn >= throwsPerTurn else { return false }
        endTurn()
        return true
    }

    /// Kończy turę przed czasem (np. bust w 501).
    public mutating func endTurn() {
        throwInTurn = 0
        currentIndex += 1
        if currentIndex == players.count {
            currentIndex = 0
            round += 1
        }
    }
}
