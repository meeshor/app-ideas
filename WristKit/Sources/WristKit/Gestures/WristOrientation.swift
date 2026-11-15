import Foundation

/// Jak zegarek jest założony: nadgarstek i strona koronki.
///
/// Z tego wynika oś „przedramię → dłoń” w układzie urządzenia. Układ Core Motion na zegarku:
/// +x od godziny 9 do 3 (w stronę koronki przy domyślnej orientacji), +y do godziny 12,
/// +z z tarczy na zewnątrz. Zakładamy, że Core Motion **nie** przelicza osi po zmianie
/// orientacji w ustawieniach.
///
/// - lewy nadgarstek, koronka od strony dłoni (domyślnie): dłoń = +x,
/// - prawy nadgarstek, koronka od strony dłoni (zegarek obrócony o 180°): dłoń = −x,
/// - koronka od strony łokcia: odwrotnie.
///
/// DO SPRAWDZENIA NA ZEGARKU: nagranie `flick_center_01` z ręką wyciągniętą do przodu
/// powinno mieć grawitację w osi dłoni bliską 0, a po podniesieniu dłoni do góry: ujemną.
public struct WristOrientation: Sendable, Hashable, Codable {
    public var wrist: WristSide
    /// Czy koronka jest od strony dłoni (domyślne ustawienie watchOS).
    public var crownTowardHand: Bool

    public init(wrist: WristSide = .right, crownTowardHand: Bool = true) {
        self.wrist = wrist
        self.crownTowardHand = crownTowardHand
    }

    /// Jednostkowa oś „przedramię → palce” w układzie urządzenia.
    public var handAxis: Vector3 {
        (wrist == .left) == crownTowardHand ? Vector3(1, 0, 0) : Vector3(-1, 0, 0)
    }
}
