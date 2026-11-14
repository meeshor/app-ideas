import Charts
import SwiftUI
import WristKit

/// Jedna seria na wykresie ruchu.
struct MotionSeries: Identifiable, Sendable {
    let name: String
    let value: @Sendable (MotionSample) -> Double
    var id: String { name }

    static let magnitudes: [MotionSeries] = [
        MotionSeries(name: "|ω| rad/s") { $0.rotationRate.length },
        MotionSeries(name: "|a| g") { $0.userAcceleration.length }
    ]

    static let rotationAxes: [MotionSeries] = [
        MotionSeries(name: "ωx") { $0.rotationRate.x },
        MotionSeries(name: "ωy") { $0.rotationRate.y },
        MotionSeries(name: "ωz") { $0.rotationRate.z }
    ]

    static let attitude: [MotionSeries] = [
        MotionSeries(name: "roll°") { $0.attitude.eulerAngles.roll * 180 / .pi },
        MotionSeries(name: "pitch°") { $0.attitude.eulerAngles.pitch * 180 / .pi },
        MotionSeries(name: "yaw°") { $0.attitude.eulerAngles.yaw * 180 / .pi }
    ]
}

private struct ChartPoint: Identifiable {
    let id: Int
    let t: Double
    let value: Double
    let series: String
}

/// Wykres liniowy wybranych serii w funkcji czasu (s od początku albo od końca).
struct MotionChart: View {
    let samples: [MotionSample]
    let series: [MotionSeries]
    /// `true`: oś X to sekundy wstecz od najnowszej próbki (podgląd na żywo).
    var relativeToEnd = false
    /// Maksymalna liczba punktów na serię (przerzedzanie dla długich nagrań).
    var maxPoints = 600

    var body: some View {
        Chart(points) { point in
            LineMark(
                x: .value("Czas [s]", point.t),
                y: .value("Wartość", point.value),
                series: .value("Seria", point.series)
            )
            .foregroundStyle(by: .value("Seria", point.series))
            .interpolationMethod(.linear)
        }
        .chartLegend(position: .top, alignment: .leading)
        .frame(minHeight: 160)
    }

    private var points: [ChartPoint] {
        guard let first = samples.first, let last = samples.last else { return [] }
        let origin = relativeToEnd ? last.t : first.t
        let step = max(1, samples.count / maxPoints)
        var result: [ChartPoint] = []
        result.reserveCapacity(series.count * samples.count / step)
        for (seriesIndex, spec) in series.enumerated() {
            for index in stride(from: 0, to: samples.count, by: step) {
                let sample = samples[index]
                result.append(ChartPoint(
                    id: seriesIndex * samples.count + index,
                    t: sample.t - origin,
                    value: spec.value(sample),
                    series: spec.name
                ))
            }
        }
        return result
    }
}
