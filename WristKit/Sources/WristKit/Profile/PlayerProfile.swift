import Foundation

/// Na którym nadgarstku jest zegarek (i którą ręką gracz rzuca).
public enum WristSide: String, Sendable, Codable, CaseIterable {
    case left
    case right

    /// Znak, przez który mnożymy yaw/roll, żeby „w prawo” znaczyło to samo dla obu rąk.
    public var mirrorSign: Double { self == .right ? 1 : -1 }
}

/// Ogólny poziom trudności: skaluje bazowy rozrzut w grach.
public enum Difficulty: String, Sendable, Codable, CaseIterable {
    case easy
    case normal
    case hard
    case pro
}

/// Indywidualne przesunięcie kierunku, wyliczone z kalibracji „rzuty w środek”.
public struct Calibration: Sendable, Hashable, Codable {
    /// Odejmowane od surowego yaw (rad).
    public var yawOffset: Double
    /// Odejmowane od surowego pitch (rad).
    public var pitchOffset: Double
    /// Ile rzutów złożyło się na kalibrację (0 = brak kalibracji).
    public var sampleCount: Int

    public init(yawOffset: Double = 0, pitchOffset: Double = 0, sampleCount: Int = 0) {
        self.yawOffset = yawOffset
        self.pitchOffset = pitchOffset
        self.sampleCount = sampleCount
    }

    public static let none = Calibration()

    /// Kalibracja ze średniej kierunków rzutów, które miały trafić w środek.
    public init(centerThrows: [(yaw: Double, pitch: Double)]) {
        guard !centerThrows.isEmpty else {
            self.init()
            return
        }
        let n = Double(centerThrows.count)
        self.init(
            yawOffset: centerThrows.map(\.yaw).reduce(0, +) / n,
            pitchOffset: centerThrows.map(\.pitch).reduce(0, +) / n,
            sampleCount: centerThrows.count
        )
    }

    public func apply(yaw: Double, pitch: Double) -> (yaw: Double, pitch: Double) {
        (yaw - yawOffset, pitch - pitchOffset)
    }
}

/// Profil gracza: wspólny dla wszystkich gier korzystających z WristKit.
public struct PlayerProfile: Sendable, Hashable, Codable, Identifiable {
    public var id: UUID
    public var name: String
    public var wrist: WristSide
    public var difficulty: Difficulty
    /// Kalibracje per rodzaj gestu (np. osobno dla rzutek i ręcznej).
    public var calibrations: [ThrowKind: Calibration]

    public init(
        id: UUID = UUID(),
        name: String,
        wrist: WristSide = .right,
        difficulty: Difficulty = .normal,
        calibrations: [ThrowKind: Calibration] = [:]
    ) {
        self.id = id
        self.name = name
        self.wrist = wrist
        self.difficulty = difficulty
        self.calibrations = calibrations
    }

    public func calibration(for kind: ThrowKind) -> Calibration {
        calibrations[kind] ?? .none
    }
}
