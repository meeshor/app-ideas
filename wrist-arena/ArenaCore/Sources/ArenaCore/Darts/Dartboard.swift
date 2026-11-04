import Foundation

/// Pole tarczy.
public enum DartRing: String, Sendable, Codable, CaseIterable {
    case miss
    case single
    case double
    case triple
    case outerBull
    case innerBull
}

/// Wynik trafienia w tarczę.
public struct DartHit: Sendable, Hashable, Codable {
    public var ring: DartRing
    /// 1…20 dla sektorów, 25 dla środka, 0 dla pudła.
    public var number: Int

    public init(ring: DartRing, number: Int) {
        self.ring = ring
        self.number = number
    }

    public static let miss = DartHit(ring: .miss, number: 0)
    public static let outerBull = DartHit(ring: .outerBull, number: 25)
    public static let innerBull = DartHit(ring: .innerBull, number: 25)
    public static func single(_ n: Int) -> DartHit { DartHit(ring: .single, number: n) }
    public static func double(_ n: Int) -> DartHit { DartHit(ring: .double, number: n) }
    public static func triple(_ n: Int) -> DartHit { DartHit(ring: .triple, number: n) }

    public var multiplier: Int {
        switch ring {
        case .miss: 0
        case .single, .outerBull: 1
        case .double, .innerBull: 2
        case .triple: 3
        }
    }

    public var score: Int { number * multiplier }

    /// Czy trafienie kończy grę w trybie double-out (środek 50 liczy się jako podwójne).
    public var isDouble: Bool { ring == .double || ring == .innerBull }
}

/// Punkt na tarczy w milimetrach od środka; x w prawo, y w górę.
public struct BoardPoint: Sendable, Hashable, Codable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public var radius: Double { (x * x + y * y).squareRoot() }
}

/// Geometria tarczy o standardowych wymiarach (promienie w mm).
public struct Dartboard: Sendable, Hashable {
    public var innerBullRadius = 6.35
    public var outerBullRadius = 15.9
    public var tripleInnerRadius = 99.0
    public var tripleOuterRadius = 107.0
    public var doubleInnerRadius = 162.0
    public var doubleOuterRadius = 170.0

    public init() {}

    public static let standard = Dartboard()

    /// Kolejność sektorów od góry, zgodnie z ruchem wskazówek zegara.
    public static let segmentOrder = [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5]
    public static let segmentAngle = 360.0 / 20

    /// Co trafiliśmy w danym punkcie.
    public func hit(at point: BoardPoint) -> DartHit {
        let r = point.radius
        if r <= innerBullRadius { return .innerBull }
        if r <= outerBullRadius { return .outerBull }
        if r > doubleOuterRadius { return .miss }

        let number = Self.segmentOrder[Self.segmentIndex(at: point)]
        if r >= doubleInnerRadius { return .double(number) }
        if r >= tripleInnerRadius, r <= tripleOuterRadius { return .triple(number) }
        return .single(number)
    }

    /// Indeks sektora (0 = 20 na górze) dla punktu.
    static func segmentIndex(at point: BoardPoint) -> Int {
        // atan2(x, y): kąt od osi „w górę”, rosnący zgodnie z ruchem wskazówek zegara.
        let degrees = atan2(point.x, point.y) * 180 / .pi
        let shifted = (degrees + segmentAngle / 2 + 360).truncatingRemainder(dividingBy: 360)
        return Int(shifted / segmentAngle) % 20
    }

    /// Środek pola: cel dla AI, podpowiedzi i testów.
    public func center(of hit: DartHit) -> BoardPoint? {
        let radius: Double
        switch hit.ring {
        case .innerBull: return BoardPoint(x: 0, y: 0)
        case .outerBull: radius = (innerBullRadius + outerBullRadius) / 2
        case .triple: radius = (tripleInnerRadius + tripleOuterRadius) / 2
        case .double: radius = (doubleInnerRadius + doubleOuterRadius) / 2
        case .single: radius = (tripleOuterRadius + doubleInnerRadius) / 2
        case .miss: return nil
        }
        let index: Int
        if hit.ring == .outerBull {
            index = 0
        } else if let found = Self.segmentOrder.firstIndex(of: hit.number) {
            index = found
        } else {
            return nil
        }
        let angle = Double(index) * Self.segmentAngle * .pi / 180
        return BoardPoint(x: radius * sin(angle), y: radius * cos(angle))
    }
}
