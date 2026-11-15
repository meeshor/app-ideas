import Foundation

/// Tarcza łucznicza z 10 pierścieniami (jak WA): pierścień = średnica / 20, X = połowa „dziesiątki”.
/// Standard: 40 cm na 18 m (hala), 80 cm na 30 m, 122 cm na 70 m.
public struct TargetFace: Sendable, Hashable, Codable {
    /// Średnica, cm.
    public var diameter: Double

    public init(diameter: Double) {
        self.diameter = diameter
    }

    public static let indoor40 = TargetFace(diameter: 40)
    public static let outdoor80 = TargetFace(diameter: 80)
    public static let outdoor122 = TargetFace(diameter: 122)

    /// Domyślna tarcza dla dystansu (m).
    public static func standard(for distance: Double) -> TargetFace {
        switch distance {
        case ..<25: .indoor40
        case ..<50: .outdoor80
        default: .outdoor122
        }
    }

    public var ringWidth: Double { diameter / 20 }

    /// Punktacja trafienia (cm od środka). Strzała na linii liczy się wyżej (jak w przepisach).
    public func score(x: Double, y: Double) -> ArrowScore {
        let r = (x * x + y * y).squareRoot()
        if r <= ringWidth / 2 { return ArrowScore(value: 10, isX: true) }
        let ring = Int(ceil(r / ringWidth - 1e-9))
        guard ring >= 1, ring <= 10 else { return ArrowScore(value: 0, isX: false) }
        return ArrowScore(value: 11 - ring, isX: false)
    }
}

/// Wynik jednej strzały: 0 (pudło) … 10, X = środek „dziesiątki” (do rozstrzygania remisów).
public struct ArrowScore: Sendable, Hashable, Codable {
    public var value: Int
    public var isX: Bool

    public init(value: Int, isX: Bool) {
        self.value = value
        self.isX = isX
    }

    public var label: String {
        if isX { return "X" }
        return value == 0 ? "M" : "\(value)"
    }
}
