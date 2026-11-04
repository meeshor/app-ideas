import Foundation
import Testing
@testable import WristKit

@Suite("Matematyka")
struct MathTests {
    @Test func vectorBasics() {
        let a = Vector3(1, 2, 2)
        #expect(a.length == 3)
        #expect(a.dot(Vector3(1, 0, 0)) == 1)
        #expect(Vector3(1, 0, 0).cross(Vector3(0, 1, 0)) == Vector3(0, 0, 1))
        #expect(Vector3.zero.normalized == .zero)
    }

    @Test func quaternionRotatesVector() {
        let q = Quaternion(axis: Vector3(0, 0, 1), angle: .pi / 2)
        let v = q.act(on: Vector3(1, 0, 0))
        #expect(abs(v.x) < 1e-9)
        #expect(abs(v.y - 1) < 1e-9)
        #expect(abs(v.z) < 1e-9)
    }

    @Test func quaternionRelativeAngle() {
        let reference = Quaternion(axis: Vector3(1, 0, 0), angle: 0.3)
        let current = reference * Quaternion(axis: Vector3(0, 0, 1), angle: 0.2)
        let rel = current.relative(to: reference)
        #expect(abs(rel.angle - 0.2) < 1e-9)
        #expect(abs(Quaternion.identity.angle) < 1e-12)
    }

    @Test func inverseCancels() {
        let q = Quaternion(axis: Vector3(1, 1, 0), angle: 1.1)
        let product = q * q.inverse
        #expect(abs(product.w - 1) < 1e-9)
        #expect(abs(product.angle) < 1e-6)
    }
}
