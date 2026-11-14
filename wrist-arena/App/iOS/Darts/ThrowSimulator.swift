import Foundation
import WristKit

/// Symulowany rzut: syntetyczny ruch ręki przepuszczony przez ten sam `FlickThrowRecognizer`,
/// który działa na zegarku. Do gry w symulatorze i bez zegarka (debug).
enum ThrowSimulator {
    /// - Parameter skill: 0 = losowo jak początkujący, 1 = bardzo powtarzalnie.
    static func throwEvent(wrist: WristSide, skill: Double = 0.6) -> ThrowEvent? {
        var rng = SystemRandomNumberGenerator()
        let wobble = 0.08 * (1 - min(max(skill, 0), 1)) + 0.01
        let orientation = WristOrientation(wrist: wrist)
        var motion = SyntheticMotion(
            orientation: orientation,
            heading: Double.random(in: -.pi ... .pi, using: &rng),
            seed: UInt64.random(in: 0...UInt64.max, using: &rng)
        )
        motion.hold(0.6)
        motion.flick(.init(
            peakRate: 12 + rng.nextGaussian() * 0.6,
            yawDeviation: rng.nextGaussian() * wobble,
            pitchDeviation: rng.nextGaussian() * wobble,
            jerkiness: abs(rng.nextGaussian()) * 0.2
        ))
        motion.hold(0.6)
        var recognizer = FlickThrowRecognizer(orientation: orientation)
        return MotionReplayer(recording: motion.recording(label: "sim")).events(&recognizer).first
    }
}
