import Foundation

/// Kwaternion jednostkowy opisujący orientację (jak `CMQuaternion`: x, y, z, w).
public struct Quaternion: Sendable, Hashable, Codable {
    public var x: Double
    public var y: Double
    public var z: Double
    public var w: Double

    public init(x: Double, y: Double, z: Double, w: Double) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }

    public static let identity = Quaternion(x: 0, y: 0, z: 0, w: 1)

    /// Obrót o `angle` radianów wokół osi `axis` (oś nie musi być znormalizowana).
    public init(axis: Vector3, angle: Double) {
        let n = axis.normalized
        let half = angle / 2
        let s = sin(half)
        self.init(x: n.x * s, y: n.y * s, z: n.z * s, w: cos(half))
    }

    public var norm: Double { (x * x + y * y + z * z + w * w).squareRoot() }

    public var normalized: Quaternion {
        let n = norm
        guard n > 0 else { return .identity }
        return Quaternion(x: x / n, y: y / n, z: z / n, w: w / n)
    }

    public var conjugate: Quaternion { Quaternion(x: -x, y: -y, z: -z, w: w) }

    /// Dla kwaternionu jednostkowego odwrotność = sprzężenie.
    public var inverse: Quaternion {
        let n2 = x * x + y * y + z * z + w * w
        guard n2 > 0 else { return .identity }
        let c = conjugate
        return Quaternion(x: c.x / n2, y: c.y / n2, z: c.z / n2, w: c.w / n2)
    }

    /// Kąt obrotu w radianach, 0…π.
    public var angle: Double {
        let q = normalized
        return 2 * atan2(Vector3(q.x, q.y, q.z).length, abs(q.w))
    }

    public static func * (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        Quaternion(
            x: lhs.w * rhs.x + lhs.x * rhs.w + lhs.y * rhs.z - lhs.z * rhs.y,
            y: lhs.w * rhs.y - lhs.x * rhs.z + lhs.y * rhs.w + lhs.z * rhs.x,
            z: lhs.w * rhs.z + lhs.x * rhs.y - lhs.y * rhs.x + lhs.z * rhs.w,
            w: lhs.w * rhs.w - lhs.x * rhs.x - lhs.y * rhs.y - lhs.z * rhs.z
        )
    }

    /// Obraca wektor `v` tym kwaternionem.
    public func act(on v: Vector3) -> Vector3 {
        let p = Quaternion(x: v.x, y: v.y, z: v.z, w: 0)
        let r = self * p * inverse
        return Vector3(r.x, r.y, r.z)
    }

    /// Obrót prowadzący od `reference` do `self`, wyrażony w układzie `reference`.
    /// Na nim liczymy kierunek rzutu względem pozy „ready”.
    public func relative(to reference: Quaternion) -> Quaternion {
        reference.inverse * self
    }
}
