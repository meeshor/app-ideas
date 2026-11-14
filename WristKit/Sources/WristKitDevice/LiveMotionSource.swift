#if os(watchOS) || os(iOS)
import CoreMotion
import Foundation
import WristKit

/// Strumień próbek z Core Motion (`CMDeviceMotion`), domyślnie 100 Hz.
///
/// `CMMotionManager` nie jest `Sendable`, więc dostęp chroni blokada,
/// a próbki są konwertowane na `MotionSample` już na kolejce czujników.
public final class LiveMotionSource: @unchecked Sendable {
    private let manager = CMMotionManager()
    private let queue: OperationQueue
    private let lock = NSLock()
    private var continuation: AsyncStream<MotionSample>.Continuation?

    public init() {
        queue = OperationQueue()
        queue.name = "WristKit.motion"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
    }

    public var isAvailable: Bool { manager.isDeviceMotionAvailable }

    /// Układ odniesienia: z kompasem (korekta dryfu yaw), jeśli urządzenie go ma.
    public static var referenceFrame: CMAttitudeReferenceFrame {
        CMMotionManager.availableAttitudeReferenceFrames().contains(.xArbitraryCorrectedZVertical)
            ? .xArbitraryCorrectedZVertical
            : .xArbitraryZVertical
    }

    /// Startuje aktualizacje. Poprzedni strumień (jeśli był) zostaje zamknięty.
    public func start(frequency: Double = 100) -> AsyncStream<MotionSample> {
        stop()
        let (stream, continuation) = AsyncStream<MotionSample>.makeStream(
            bufferingPolicy: .bufferingNewest(1_000)
        )
        lock.withLock { self.continuation = continuation }
        manager.deviceMotionUpdateInterval = 1 / frequency
        manager.startDeviceMotionUpdates(using: Self.referenceFrame, to: queue) { motion, _ in
            guard let motion else { return }
            continuation.yield(MotionSample(motion))
        }
        return stream
    }

    public func stop() {
        manager.stopDeviceMotionUpdates()
        let previous = lock.withLock { () -> AsyncStream<MotionSample>.Continuation? in
            defer { continuation = nil }
            return continuation
        }
        previous?.finish()
    }
}

extension MotionSample {
    init(_ motion: CMDeviceMotion) {
        let q = motion.attitude.quaternion
        let r = motion.rotationRate
        let a = motion.userAcceleration
        let g = motion.gravity
        self.init(
            t: motion.timestamp,
            attitude: Quaternion(x: q.x, y: q.y, z: q.z, w: q.w),
            rotationRate: Vector3(r.x, r.y, r.z),
            userAcceleration: Vector3(a.x, a.y, a.z),
            gravity: Vector3(g.x, g.y, g.z)
        )
    }
}
#endif
