import Foundation
import WristKit

public typealias PlayerID = UUID

/// Skąd przychodzą rzuty.
public enum InputKind: String, Sendable, Codable, CaseIterable {
    /// Gest rozpoznany na Apple Watch.
    case watch
    /// Przeciągnięcie palcem po ekranie.
    case touch
    /// Ruch telefonu trzymanego w dłoni (tylko z wciśniętym przyciskiem, bez puszczania telefonu).
    case phoneMotion
    /// Odtwarzanie nagrania (debug, testy).
    case replay
}

/// Opis modułu gry: to, co menu i warstwa wejścia muszą wiedzieć bez ładowania UI.
public struct ModuleDescriptor: Sendable, Hashable, Identifiable {
    public var id: String
    public var name: String
    public var requiredGesture: ThrowKind
    public var supportedInputs: Set<InputKind>
    public var playerRange: ClosedRange<Int>

    public init(
        id: String,
        name: String,
        requiredGesture: ThrowKind,
        supportedInputs: Set<InputKind>,
        playerRange: ClosedRange<Int>
    ) {
        self.id = id
        self.name = name
        self.requiredGesture = requiredGesture
        self.supportedInputs = supportedInputs
        self.playerRange = playerRange
    }
}

/// Komunikat z reguł dla UI (napisy, dźwięki, haptyka).
public enum GameNotice: Sendable, Hashable, Codable {
    case scored(player: PlayerID, points: Int)
    case bust(player: PlayerID)
    case turnEnded(next: PlayerID)
    case finished(winner: PlayerID)
    case message(String)
}

/// Wynik zastosowania jednego rzutu.
public struct RulesStep<State: Sendable>: Sendable {
    public var state: State
    public var notices: [GameNotice]

    public init(state: State, notices: [GameNotice] = []) {
        self.state = state
        self.notices = notices
    }
}

/// Reguły jednego wariantu gry (501, Cricket, …). Czyste funkcje: łatwe do testów i do
/// zapisu stanu meczu. Moduł UI (`GameModule` w aplikacji) opakowuje reguły w ekran.
public protocol GameRules: Sendable {
    associatedtype State: Sendable, Codable, Equatable
    /// Wynik pojedynczego rzutu, np. `DartHit` w rzutkach.
    associatedtype Shot: Sendable

    var descriptor: ModuleDescriptor { get }

    func start(players: [PlayerID]) -> State
    func apply(_ shot: Shot, to state: State) -> RulesStep<State>
    func winner(of state: State) -> PlayerID?
}

/// Katalog modułów pakietu.
public enum ModuleCatalog {
    public static let darts = ModuleDescriptor(
        id: "darts",
        name: "Rzutki",
        requiredGesture: .flick,
        supportedInputs: [.watch, .touch, .phoneMotion, .replay],
        playerRange: 1...4
    )

    public static let all: [ModuleDescriptor] = [darts]
}
