import Foundation
@testable import WristKit

/// Syntetyczne odpowiedniki nagrań z docs/recording-protocol.md (plus kilka dodatkowych).
/// Każde: ~1 s spoczynku, gest, ~1 s spoczynku.
enum SyntheticFixtures {
    typealias Build = @Sendable (inout SyntheticMotion) -> Void

    struct Case: Sendable {
        var label: String
        var wrist: WristSide
        var heading: Double
        var seed: UInt64
        var build: Build

        init(_ label: String, _ wrist: WristSide, _ heading: Double, _ seed: UInt64, _ build: @escaping Build) {
            self.label = label
            self.wrist = wrist
            self.heading = heading
            self.seed = seed
            self.build = build
        }
    }

    static let cases: [Case] = [
        Case("flick_center_01", .right, 0, 1, { $0.flick(.init()) }),
        Case("flick_center_02", .right, 0, 2, { $0.flick(.init(peakRate: 11)) }),
        Case("flick_center_03", .right, 0, 3, { $0.flick(.init(peakRate: 13, duration: 0.17)) }),
        // Gracz stoi bokiem do „północy” zegarka i trzyma zegarek przekręcony: kierunek ma wyjść tak samo.
        Case("flick_center_04", .right, 1.1, 4, { $0.flick(.init()) }),
        Case("flick_left_01", .right, 0, 5, { $0.flick(.init(yawDeviation: -0.15)) }),
        Case("flick_right_01", .right, 0, 6, { $0.flick(.init(yawDeviation: 0.15)) }),
        Case("flick_high_01", .right, 0, 7, { $0.flick(.init(pitchDeviation: 0.12)) }),
        Case("flick_low_01", .right, 0, 8, { $0.flick(.init(pitchDeviation: -0.12)) }),
        Case("flick_weak_01", .right, 0, 9, { $0.flick(.init(peakRate: 3, duration: 0.3)) }),
        Case("flick_strong_01", .right, 0, 10, { $0.flick(.init(peakRate: 20, duration: 0.14)) }),
        Case("flick_twist_01", .right, 0, 11, { $0.flick(.init(spinRate: 7)) }),
        Case("flick_jerky_01", .right, 0, 12, { $0.flick(.init(jerkiness: 0.6)) }),
        Case("flick_nobackswing_01", .right, 0, 13, { $0.flick(.init(backswing: false)) }),
        Case("flick_series_01", .right, 0, 14, { motion in
            for _ in 0..<3 {
                motion.flick(.init())
                motion.hold(2)
            }
        }),
        Case("flick_lefthand_01", .left, 0, 15, { $0.flick(.init()) }),
        Case("noise_scratch_01", .right, 0, 16, { $0.scratch() }),
        Case("noise_wave_01", .right, 0, 17, { $0.wave() }),
        Case("noise_lower_01", .right, 0, 18, { $0.lowerArm() }),
        Case("noise_twist_01", .right, 0, 19, { $0.twist() }),
        Case("idle_tremor_01", .right, 0, 20, { $0.hold(5) })
    ]

    static func recording(_ index: Int) -> MotionRecording {
        let item = cases[index]
        var motion = SyntheticMotion(
            orientation: WristOrientation(wrist: item.wrist),
            heading: item.heading,
            roll: item.heading * 0.4,
            seed: item.seed
        )
        motion.hold(1)
        item.build(&motion)
        motion.hold(1)
        return motion.recording(label: item.label)
    }

    static var all: [MotionRecording] { cases.indices.map(recording) }
}
