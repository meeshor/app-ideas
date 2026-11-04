import Foundation
import Testing
@testable import ArenaCore

@Suite("Tarcza")
struct DartboardTests {
    let board = Dartboard.standard

    @Test func bullsAndMiss() {
        #expect(board.hit(at: BoardPoint(x: 0, y: 0)) == .innerBull)
        #expect(board.hit(at: BoardPoint(x: 0, y: 10)) == .outerBull)
        #expect(board.hit(at: BoardPoint(x: 0, y: 171)) == .miss)
        #expect(DartHit.innerBull.score == 50)
        #expect(DartHit.outerBull.score == 25)
        #expect(DartHit.innerBull.isDouble)
    }

    @Test func ringsOnTwenty() {
        #expect(board.hit(at: BoardPoint(x: 0, y: 103)) == .triple(20))
        #expect(board.hit(at: BoardPoint(x: 0, y: 166)) == .double(20))
        #expect(board.hit(at: BoardPoint(x: 0, y: 60)) == .single(20))
        #expect(board.hit(at: BoardPoint(x: 0, y: 130)) == .single(20))
        #expect(DartHit.triple(20).score == 60)
    }

    @Test func compassDirections() {
        #expect(board.hit(at: BoardPoint(x: 130, y: 0)) == .single(6))
        #expect(board.hit(at: BoardPoint(x: 0, y: -130)) == .single(3))
        #expect(board.hit(at: BoardPoint(x: -130, y: 0)) == .single(11))
    }

    @Test(arguments: Dartboard.segmentOrder)
    func centersResolveBack(number: Int) throws {
        for hit in [DartHit.single(number), .double(number), .triple(number)] {
            let point = try #require(board.center(of: hit))
            #expect(board.hit(at: point) == hit)
        }
    }

    @Test func bullCentersResolveBack() throws {
        let outer = try #require(board.center(of: .outerBull))
        let inner = try #require(board.center(of: .innerBull))
        #expect(board.hit(at: outer) == .outerBull)
        #expect(board.hit(at: inner) == .innerBull)
        #expect(board.center(of: .miss) == nil)
    }
}

@Suite("Tury")
struct TurnOrderTests {
    @Test func rotatesPlayersEveryThreeThrows() {
        let players = [UUID(), UUID(), UUID()]
        var order = TurnOrder(players: players)
        #expect(order.current == players[0])
        #expect(!order.recordThrow())
        #expect(!order.recordThrow())
        #expect(order.recordThrow())
        #expect(order.current == players[1])
        order.endTurn()
        order.endTurn()
        #expect(order.current == players[0])
        #expect(order.round == 2)
        #expect(order.throwInTurn == 0)
    }

    @Test func catalogHasDarts() {
        #expect(ModuleCatalog.all.contains(ModuleCatalog.darts))
        #expect(ModuleCatalog.darts.requiredGesture == .flick)
        #expect(ModuleCatalog.darts.playerRange.contains(4))
    }
}
