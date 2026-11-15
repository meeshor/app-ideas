import Foundation
import WristKit

/// Symulowany rzut: syntetyczny ruch ręki przepuszczony przez ten sam `FlickThrowRecognizer`,
/// który działa na zegarku. Do gry w symulatorze i bez zegarka (debug).
enum ThrowSimulator {
    /// - Parameter skill: 0 = losowo jak początkujący, 1 = bardzo powtarzalnie.
    static func throwEvent(wrist: WristSide, skill: Double = 0.6, tuning: FlickTuning = FlickTuning()) -> ThrowEvent? {
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
        var recognizer = FlickThrowRecognizer(tuning: tuning, orientation: orientation)
        return MotionReplayer(recording: motion.recording(label: "sim")).events(&recognizer).first
    }

    /// Symulowany rzut nad głową (ręczna); `feints` zwodów przed rzutem. Zwraca wszystkie zdarzenia.
    static func overarmEvents(
        wrist: WristSide,
        feints: Int = 0,
        skill: Double = 0.6,
        tuning: OverarmTuning = OverarmTuning()
    ) -> [ThrowEvent] {
        var rng = SystemRandomNumberGenerator()
        let wobble = 0.12 * (1 - min(max(skill, 0), 1)) + 0.02
        let orientation = WristOrientation(wrist: wrist)
        var motion = SyntheticMotion(
            orientation: orientation,
            heading: Double.random(in: -.pi ... .pi, using: &rng),
            elevation: 0.8,
            seed: UInt64.random(in: 0...UInt64.max, using: &rng)
        )
        motion.hold(0.6)
        for _ in 0..<feints {
            motion.feint()
            motion.hold(0.4)
        }
        motion.overarm(.init(
            peakRate: 16 + rng.nextGaussian() * 1.5,
            yawDeviation: rng.nextGaussian() * wobble * 1.5,
            // W generatorze odchylenie w pionie spowalnia zamach; duże wartości dawałyby „zwód”.
            pitchDeviation: rng.nextGaussian() * wobble * 0.5,
            spinRate: rng.nextGaussian() * 2
        ))
        motion.hold(1)
        var recognizer = OverarmThrowRecognizer(tuning: tuning, orientation: orientation)
        return MotionReplayer(recording: motion.recording(label: "sim")).events(&recognizer)
    }

    /// Sam rzut (bez zwodów) do kalibracji.
    static func overarmEvent(wrist: WristSide, skill: Double = 0.6, tuning: OverarmTuning = OverarmTuning()) -> ThrowEvent? {
        overarmEvents(wrist: wrist, skill: skill, tuning: tuning).first { !$0.isFeint }
    }
}
