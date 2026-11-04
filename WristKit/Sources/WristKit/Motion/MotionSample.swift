import Foundation

/// Pojedyncza próbka ruchu z zegarka (odpowiednik `CMDeviceMotion`).
///
/// Kodowana kompaktowo jako płaska tablica 14 liczb:
/// `[t, qx, qy, qz, qw, rx, ry, rz, ax, ay, az, gx, gy, gz]`,
/// bo nagrania mają 100 próbek na sekundę.
public struct MotionSample: Sendable, Hashable {
    /// Czas w sekundach według zegara zegarka (`CMLogItem.timestamp`, od uruchomienia urządzenia).
    public var t: TimeInterval
    /// Orientacja w układzie `xArbitraryCorrectedZVertical`.
    public var attitude: Quaternion
    /// Prędkość kątowa w rad/s, w układzie urządzenia.
    public var rotationRate: Vector3
    /// Przyspieszenie użytkownika (bez grawitacji) w g, w układzie urządzenia.
    public var userAcceleration: Vector3
    /// Wektor grawitacji w g, w układzie urządzenia.
    public var gravity: Vector3

    public init(
        t: TimeInterval,
        attitude: Quaternion = .identity,
        rotationRate: Vector3 = .zero,
        userAcceleration: Vector3 = .zero,
        gravity: Vector3 = Vector3(0, 0, -1)
    ) {
        self.t = t
        self.attitude = attitude
        self.rotationRate = rotationRate
        self.userAcceleration = userAcceleration
        self.gravity = gravity
    }
}

extension MotionSample: Codable {
    public init(from decoder: any Decoder) throws {
        var c = try decoder.unkeyedContainer()
        func next() throws -> Double { try c.decode(Double.self) }
        t = try next()
        attitude = Quaternion(x: try next(), y: try next(), z: try next(), w: try next())
        rotationRate = Vector3(try next(), try next(), try next())
        userAcceleration = Vector3(try next(), try next(), try next())
        gravity = Vector3(try next(), try next(), try next())
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.unkeyedContainer()
        for value in [
            t,
            attitude.x, attitude.y, attitude.z, attitude.w,
            rotationRate.x, rotationRate.y, rotationRate.z,
            userAcceleration.x, userAcceleration.y, userAcceleration.z,
            gravity.x, gravity.y, gravity.z
        ] {
            try c.encode(value)
        }
    }
}
