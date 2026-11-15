import Foundation

/// Charakterystyka łuku. Wartości startowe: łuk olimpijski (refleksyjny) z amatorskim naciągiem.
public struct BowSpec: Sendable, Hashable, Codable {
    public var name: String
    /// Prędkość strzały przy minimalnym uznanym naciągu, m/s. DO STROJENIA.
    public var minSpeed: Double
    /// Prędkość przy pełnym naciągu, m/s. Łuk olimpijski ~55–65 m/s (typowe pomiary chronografem).
    public var maxSpeed: Double
    /// Opór: a = −k·|v_wzgl|·v_wzgl, 1/m. Szacunek k = ½·ρ·Cd·A/m ≈ ½·1,2·2·3,3e−5/0,02 ≈ 0,002
    /// (ρ powietrza, Cd strzały z lotkami ~2, przekrój trzonu 6,5 mm, masa 20 g). DO STROJENIA.
    public var drag: Double

    public init(name: String, minSpeed: Double, maxSpeed: Double, drag: Double) {
        self.name = name
        self.minSpeed = minSpeed
        self.maxSpeed = maxSpeed
        self.drag = drag
    }

    public static let recurve = BowSpec(name: "Refleksyjny", minSpeed: 30, maxSpeed: 58, drag: 0.0018)

    /// Prędkość początkowa dla siły naciągu 0…1.
    public func speed(strength: Double) -> Double {
        minSpeed + (maxSpeed - minSpeed) * min(1, max(0, strength))
    }
}

/// Wiatr w płaszczyźnie poziomej, m/s: `cross` > 0 wieje w prawo, `head` > 0 wieje w twarz strzelca.
public struct Wind: Sendable, Hashable, Codable {
    public var cross: Double
    public var head: Double

    public init(cross: Double = 0, head: Double = 0) {
        self.cross = cross
        self.head = head
    }

    public static let calm = Wind()

    public var speed: Double { (cross * cross + head * head).squareRoot() }
}

/// Wynik lotu: punkt w płaszczyźnie tarczy (m, x w prawo, y w górę względem linii celowania) i czas.
public struct Flight: Sendable, Hashable {
    public var x: Double
    public var y: Double
    public var time: Double
    public var impactSpeed: Double
}

/// Balistyka strzały: grawitacja + opór kwadratowy względem powietrza (z wiatrem), całkowanie numeryczne.
public struct Ballistics: Sendable, Hashable {
    public var bow: BowSpec
    public var gravity = 9.81
    /// Krok całkowania, s (0,5 ms: błąd ≪ 1 mm na 70 m).
    public var step = 0.0005

    public init(bow: BowSpec = .recurve) {
        self.bow = bow
    }

    /// Lot do płaszczyzny tarczy w odległości `distance` (m).
    /// `elevation` i `yaw` to kąty wylotu względem linii celowania (rad).
    public func fly(speed: Double, elevation: Double, yaw: Double, wind: Wind, distance: Double) -> Flight {
        // Układ: z do tarczy, x w prawo, y w górę. Wiatr w twarz = −z.
        var position = (x: 0.0, y: 0.0, z: 0.0)
        var velocity = (
            x: speed * cos(elevation) * sin(yaw),
            y: speed * sin(elevation),
            z: speed * cos(elevation) * cos(yaw)
        )
        var time = 0.0
        while position.z < distance, time < 10 {
            let relative = (x: velocity.x - wind.cross, y: velocity.y, z: velocity.z + wind.head)
            let magnitude = (relative.x * relative.x + relative.y * relative.y + relative.z * relative.z).squareRoot()
            let k = bow.drag * magnitude
            let previous = position
            velocity.x -= k * relative.x * step
            velocity.y -= (gravity + k * relative.y) * step
            velocity.z -= k * relative.z * step
            position.x += velocity.x * step
            position.y += velocity.y * step
            position.z += velocity.z * step
            time += step
            if position.z >= distance {
                // Interpolacja liniowa do dokładnej płaszczyzny tarczy.
                let f = (distance - previous.z) / (position.z - previous.z)
                let speedNow = (velocity.x * velocity.x + velocity.y * velocity.y + velocity.z * velocity.z).squareRoot()
                return Flight(
                    x: previous.x + (position.x - previous.x) * f,
                    y: previous.y + (position.y - previous.y) * f,
                    time: time - step * (1 - f),
                    impactSpeed: speedNow
                )
            }
        }
        return Flight(x: position.x, y: position.y, time: time, impactSpeed: 0)
    }

    /// Kąt celownika: o ile wyżej wylatuje strzała przy pełnym naciągu, żeby bez wiatru trafić w punkt celowania.
    /// Celownik w łuku ustawia się raz na dystans — słabszy naciąg opada poniżej.
    public func sightElevation(distance: Double) -> Double {
        var low = 0.0, high = 0.2
        for _ in 0..<40 {
            let mid = (low + high) / 2
            let flight = fly(speed: bow.speed(strength: 1), elevation: mid, yaw: 0, wind: .calm, distance: distance)
            if flight.y < 0 { low = mid } else { high = mid }
        }
        return (low + high) / 2
    }
}
