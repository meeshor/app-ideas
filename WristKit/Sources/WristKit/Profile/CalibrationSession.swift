import Foundation

/// Kalibracja „N rzutów w środek”: zbiera kierunki, odrzuca serię zbyt rozrzuconą
/// i wylicza `Calibration` (średnie przesunięcie yaw/pitch).
///
/// Dlaczego to potrzebne: kąty w `ThrowEvent` są względne do pozy „ready”, a każdy rzuca
/// trochę inaczej (np. pitch w chwili szczytu jest zwykle ujemny, bo ręka już opada).
/// Kalibracja przesuwa „środek” na typowy rzut danego gracza.
public struct CalibrationSession: Sendable, Hashable {
    public enum Status: Sendable, Hashable {
        /// Potrzeba jeszcze `remaining` rzutów.
        case needMore(remaining: Int)
        /// Seria zbyt rozrzucona: zaczynamy od nowa (UI: „spróbuj rzucać tak samo”).
        case inconsistent(spread: Double)
        case done(Calibration)
    }

    /// DO STROJENIA: ile rzutów składa się na kalibrację.
    public var requiredThrows: Int
    /// DO STROJENIA: maks. odległość kątowa rzutu od średniej serii, rad (~11°).
    public var maxSpread: Double

    public private(set) var directions: [(yaw: Double, pitch: Double)] = []

    public init(requiredThrows: Int = 3, maxSpread: Double = 0.2) {
        precondition(requiredThrows > 0)
        self.requiredThrows = requiredThrows
        self.maxSpread = maxSpread
    }

    public var remaining: Int { max(0, requiredThrows - directions.count) }

    public mutating func add(_ event: ThrowEvent) -> Status {
        add(yaw: event.yaw, pitch: event.pitch)
    }

    public mutating func add(yaw: Double, pitch: Double) -> Status {
        directions.append((yaw, pitch))
        guard directions.count >= requiredThrows else {
            return .needMore(remaining: remaining)
        }
        let calibration = Calibration(centerThrows: directions)
        let spread = directions.map { direction in
            let dy = direction.yaw - calibration.yawOffset
            let dp = direction.pitch - calibration.pitchOffset
            return (dy * dy + dp * dp).squareRoot()
        }.max() ?? 0
        guard spread <= maxSpread else {
            directions.removeAll()
            return .inconsistent(spread: spread)
        }
        return .done(calibration)
    }

    public mutating func reset() {
        directions.removeAll()
    }

    public static func == (lhs: CalibrationSession, rhs: CalibrationSession) -> Bool {
        lhs.requiredThrows == rhs.requiredThrows && lhs.maxSpread == rhs.maxSpread
            && lhs.directions.elementsEqual(rhs.directions) { $0 == $1 }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(requiredThrows)
        hasher.combine(maxSpread)
        for direction in directions {
            hasher.combine(direction.yaw)
            hasher.combine(direction.pitch)
        }
    }
}
