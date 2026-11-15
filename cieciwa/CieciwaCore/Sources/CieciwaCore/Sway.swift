import Foundation
import WristKit

// ============================================================================
// DO STROJENIA
// Kołysanie celownika: „uspokój się i oddychaj”. Wartości startowe do strojenia w grze.
// ============================================================================

public struct SwayTuning: Sendable, Hashable, Codable {
    /// Bazowa amplituda kołysania przy idealnej kotwicy, mrad (1 mrad = 1 cm na 10 m).
    public var base: Double = 1.2
    /// Przyrost amplitudy na każdy rad/s RMS żyroskopu w kotwicy (×).
    public var stabilityGain: Double = 12
    /// Tętno spoczynkowe, jeśli gracz go nie podał, bpm.
    public var defaultRestingHeartRate: Double = 70
    /// Przyrost amplitudy na każde 10 bpm ponad spoczynkowe (×).
    public var heartRateGainPer10: Double = 0.15
    /// Okno „idealnego” strzału (prompt: 2–4 s).
    public var idealHold: ClosedRange<Double> = 2...4
    /// Przed oknem: ręka jeszcze się układa — dodatkowy przyrost na każdą sekundę brakującą (×).
    public var settleGainPerSecond: Double = 0.6
    /// Po oknie: zmęczenie — przyrost na każdą sekundę ponad okno (×).
    public var fatigueGainPerSecond: Double = 0.35
    /// Losowy rozrzut w chwili puszczenia (szarpnięcie palców), mrad.
    public var releaseNoise: Double = 0.4

    public init() {}
}

/// Kołysanie celownika: amplituda z warunków strzału i deterministyczny „ruch” celownika w czasie.
public struct SwayModel: Sendable, Hashable, Codable {
    public var tuning: SwayTuning

    public init(tuning: SwayTuning = SwayTuning()) {
        self.tuning = tuning
    }

    /// Amplituda kołysania, mrad.
    public func amplitude(stability: Double, heartRate: Double?, restingHeartRate: Double? = nil, holdTime: Double) -> Double {
        let rest = restingHeartRate ?? tuning.defaultRestingHeartRate
        let hrExcess = max(0, (heartRate ?? rest) - rest)
        let settle = max(0, tuning.idealHold.lowerBound - holdTime) * tuning.settleGainPerSecond
        let fatigue = max(0, holdTime - tuning.idealHold.upperBound) * tuning.fatigueGainPerSecond
        return tuning.base
            * (1 + tuning.stabilityGain * max(0, stability))
            * (1 + tuning.heartRateGainPer10 * hrExcess / 10)
            * (1 + settle + fatigue)
    }

    /// Położenie celownika względem punktu celowania w chwili `time` (mrad): suma wolnych sinusoid
    /// o fazach z ziarna, przeskalowana amplitudą. Ta sama funkcja rysuje celownik na żywo i rozstrzyga strzał.
    public func offset(at time: Double, amplitude: Double, seed: UInt64) -> (x: Double, y: Double) {
        var rng = SeededRandom(seed: seed)
        let phases = (0..<6).map { _ in Double.random(in: 0..<(2 * .pi), using: &rng) }
        let frequencies = [0.31, 0.73, 1.37]
        let weights = [0.6, 0.3, 0.15]
        var x = 0.0, y = 0.0
        for i in 0..<3 {
            x += weights[i] * sin(2 * .pi * frequencies[i] * time + phases[i])
            y += weights[i] * sin(2 * .pi * frequencies[i] * 1.13 * time + phases[i + 3])
        }
        // Suma wag = 1,05 → maks. wychylenie ≈ amplituda.
        return (x * amplitude / 1.05, y * amplitude / 1.05)
    }
}
