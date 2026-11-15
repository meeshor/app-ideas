import ArenaCore
import SwiftUI
import UIKit
import WristKit

/// Strojenie progów na żywo: suwaki → zegarek, lista ostatnich rzutów z parametrami.
struct TuningLabView: View {
    @State private var model = TuningLabModel()

    var body: some View {
        @Bindable var store = model.store
        List {
            sessionSection
            throwsSection
            Section {
                ForEach(FlickSliders.all) { spec in
                    TuningSlider(spec: spec, value: spec.binding(on: $store.gesture.flick))
                }
                OptionalSlider(
                    title: "Min. wzniesienie przedramienia w „ready”",
                    value: $store.gesture.flick.minReadyElevation,
                    range: -1.5...1.2,
                    defaultValue: -0.5,
                    unit: "rad"
                )
            } header: {
                Text("Gest: rzut z nadgarstka")
            } footer: {
                Text("Zmiany idą na zegarek po 0,3 s. Opis progów: docs/tuning.md.")
            }
            Section("Gest: spoczynek („gotowy”)") {
                ForEach(StillnessSliders.all) { spec in
                    TuningSlider(spec: spec, value: spec.binding(on: $store.gesture.flick.stillness))
                }
            }
            Section("Rzutki: rzut → tarcza (nowe mecze)") {
                ForEach(DartsSliders.all) { spec in
                    TuningSlider(spec: spec, value: spec.binding(on: $store.darts))
                }
                ForEach(Difficulty.allCases, id: \.self) { level in
                    let tuning = model.store
                    TuningSlider(
                        spec: SliderSpec(id: level.rawValue, title: "Rozrzut: \(Self.name(of: level))", range: 2...40, unit: "mm"),
                        value: Binding(
                            get: { tuning.darts.baseSpread(for: level) },
                            set: { tuning.darts.spread[level] = $0 }
                        )
                    )
                }
            }
            Section {
                Button("Kopiuj ustawienia (JSON)") { UIPasteboard.general.string = model.store.exportJSON }
                Button("Przywróć domyślne: gest", role: .destructive) { model.store.resetGesture() }
                Button("Przywróć domyślne: rzutki", role: .destructive) { model.store.resetDarts() }
            }
        }
        .navigationTitle("Strojenie")
        .onAppear { model.activate() }
        .onDisappear { model.deactivate() }
        .onChange(of: model.store.gesture) { model.scheduleSend() }
    }

    static func name(of level: Difficulty) -> String {
        switch level {
        case .easy: "łatwy"
        case .normal: "normalny"
        case .hard: "trudny"
        case .pro: "pro"
        }
    }

    private var sessionSection: some View {
        Section("Zegarek") {
            HStack {
                Button(model.isSessionRunning ? "Zatrzymaj rozpoznawanie" : "Start rozpoznawania") {
                    model.toggleSession()
                }
                Spacer()
                WatchPhaseLabel(phase: model.phase, reachable: model.isReachable)
            }
            Button("Symulowany rzut (bieżące progi)") { model.simulate() }
            if model.lastSimulationFailed {
                Text("Wzorcowy rzut syntetyczny nie przeszedł przez te progi.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            if let sent = model.lastSent {
                LabeledContent("Progi wysłane", value: sent.formatted(date: .omitted, time: .standard))
                    .font(.caption)
            }
        }
    }

    private var throwsSection: some View {
        Section {
            if model.throwsReceived.isEmpty {
                Text("Rzuć z zegarkiem albo użyj symulacji.").foregroundStyle(.secondary)
            }
            ForEach(model.throwsReceived) { item in
                ThrowRow(item: item)
            }
            if let averages = model.averages {
                let speed = StatFormat.decimal(averages.speed)
                Text("Średnio z \(averages.count): prędkość \(speed) m/s, jerk \(StatFormat.decimal(averages.jerk))")
                    .font(.caption.monospacedDigit())
            }
        } header: {
            HStack {
                Text("Ostatnie rzuty")
                Spacer()
                Button("Wyczyść") { model.clear() }
                    .font(.caption)
            }
        }
    }
}

private struct ThrowRow: View {
    let item: TunedThrow

    var body: some View {
        let e = item.event
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(item.receivedAt.formatted(date: .omitted, time: .standard))
                if item.simulated {
                    Text("symulacja").font(.caption2).foregroundStyle(.secondary)
                }
            }
            .font(.caption)
            Text("v \(StatFormat.decimal(e.speed)) m/s · yaw \(Self.degrees(e.yaw)) · pitch \(Self.degrees(e.pitch))")
            Text("spin \(StatFormat.decimal(e.spin)) rad/s · jerk \(StatFormat.decimal(e.jerk))")
                .foregroundStyle(.secondary)
        }
        .font(.callout.monospacedDigit())
    }

    static func degrees(_ radians: Double) -> String {
        "\(StatFormat.decimal(radians * 180 / .pi))°"
    }
}

// MARK: - Suwaki

/// Opis suwaka: zakres, krok i jednostka.
struct SliderSpec: Identifiable {
    var id: String
    var title: String
    var range: ClosedRange<Double>
    var unit: String
}

/// Suwak powiązany z polem struktury przez `WritableKeyPath`.
struct KeyedSlider<Root>: Identifiable {
    var spec: SliderSpec
    var keyPath: WritableKeyPath<Root, Double>

    var id: String { spec.id }

    init(_ id: String, _ title: String, _ keyPath: WritableKeyPath<Root, Double>, _ range: ClosedRange<Double>, _ unit: String) {
        self.spec = SliderSpec(id: id, title: title, range: range, unit: unit)
        self.keyPath = keyPath
    }

    func binding(on root: Binding<Root>) -> Binding<Double> {
        let keyPath = keyPath
        return Binding(get: { root.wrappedValue[keyPath: keyPath] }, set: { root.wrappedValue[keyPath: keyPath] = $0 })
    }
}

extension TuningSlider {
    init<Root>(spec: KeyedSlider<Root>, value: Binding<Double>) {
        self.init(spec: spec.spec, value: value)
    }
}

@MainActor
enum FlickSliders {
    static let all: [KeyedSlider<FlickTuning>] = [
        .init("start", "Start ruchu |ω|", \.startRotationRate, 0.5...5, "rad/s"),
        .init("peak", "Min. szczyt |ω|", \.minPeakRotationRate, 1...15, "rad/s"),
        .init("accel", "Min. szczyt |a|", \.minPeakAcceleration, 0.3...5, "g"),
        .init("drop", "Puszczenie: spadek do", \.releaseDropRatio, 0.2...0.9, "× szczytu"),
        .init("pause", "Tolerancja pauzy", \.pauseTolerance, 0...0.5, "s"),
        .init("maxActive", "Maks. czas rzutu", \.maxActiveDuration, 0.2...2, "s"),
        .init("confirm", "Okno potwierdzenia", \.confirmWindow, 0...0.5, "s"),
        .init("rebound", "Odbicie wstecz", \.reboundRatio, 0.2...1.5, "× szczytu"),
        .init("spinShare", "Maks. udział skrętu", \.maxSpinShare, 0.5...1, ""),
        .init("readyTimeout", "Ruch w „ready” do", \.readyTimeout, 0.2...3, "s"),
        .init("cooldown", "Przerwa po rzucie", \.cooldown, 0.2...2, "s"),
        .init("lever", "Ramię dźwigni", \.leverArm, 0.2...0.6, "m"),
        .init("jerkUnit", "Jerk = 1 przy", \.jerkForUnit, 10...600, "g/s")
    ]
}

@MainActor
enum StillnessSliders {
    static let all: [KeyedSlider<StillnessTuning>] = [
        .init("stillRate", "Maks. |ω| w spoczynku", \.maxRotationRate, 0.1...2, "rad/s"),
        .init("stillAccel", "Maks. |a| w spoczynku", \.maxUserAcceleration, 0.02...0.3, "g"),
        .init("stillTime", "Spoczynek przez", \.minDuration, 0.1...1, "s")
    ]
}

@MainActor
enum DartsSliders {
    static let all: [KeyedSlider<DartsTuning>] = [
        .init("aimGain", "Czułość celowania", \.aimGain, 0.2...1.5, "×"),
        .init("refSpeed", "Prędkość referencyjna", \.referenceSpeed, 1...10, "m/s"),
        .init("drop", "Opadanie przy 0,8 v", \.dropAtEightyPercent, 0...150, "mm"),
        .init("jerkGain", "Kara za jerk", \.jerkSpreadGain, 0...2, "×"),
        .init("spinGain", "Kara za skręt", \.spinSpreadGain, 0...0.5, "×"),
        .init("spinCurve", "Skręt toru", \.spinCurve, 0...10, "mm/(rad/s)")
    ]
}

struct TuningSlider: View {
    let spec: SliderSpec
    @Binding var value: Double

    init(spec: SliderSpec, value: Binding<Double>) {
        self.spec = spec
        self._value = value
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(spec.title)
                Spacer()
                Text("\(value.formatted(.number.precision(.significantDigits(3)))) \(spec.unit)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .font(.callout)
            Slider(value: $value, in: spec.range)
        }
    }
}

/// Suwak dla progu, który można wyłączyć (`nil`).
private struct OptionalSlider: View {
    let title: String
    @Binding var value: Double?
    let range: ClosedRange<Double>
    let defaultValue: Double
    let unit: String

    var body: some View {
        Toggle(title, isOn: Binding(get: { value != nil }, set: { value = $0 ? defaultValue : nil }))
            .font(.callout)
        if let current = value {
            TuningSlider(
                spec: SliderSpec(id: title, title: "Próg", range: range, unit: unit),
                value: Binding(get: { current }, set: { value = $0 })
            )
        }
    }
}
