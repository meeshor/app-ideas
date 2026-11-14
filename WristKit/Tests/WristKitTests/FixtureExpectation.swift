import Foundation
@testable import WristKit

/// Oczekiwany wynik nagrania, wyprowadzony z etykiety (tabela w docs/recording-protocol.md).
///
/// Kierunki porównujemy ze średnią z rzutów `flick_center_*` z tego samego zestawu, bo surowe
/// kąty zależą od stylu rzutu (dlatego w grze jest kalibracja).
enum FixtureExpectation: Equatable {
    /// Dokładnie tyle rzutów, bez sprawdzania kierunku.
    case count(Int)
    case center
    case left, right, high, low
    /// 0 rzutów albo 1 wyraźnie wolniejszy niż średni rzut w środek.
    case weak
    case strong
    case twist
    case jerky

    init?(label: String) {
        let kind = Self.kind(of: label)
        switch kind {
        case "flick_center": self = .center
        case "flick_left": self = .left
        case "flick_right": self = .right
        case "flick_high": self = .high
        case "flick_low": self = .low
        case "flick_weak": self = .weak
        case "flick_strong": self = .strong
        case "flick_twist": self = .twist
        case "flick_jerky": self = .jerky
        case "flick_series": self = .count(3)
        default:
            if kind.hasPrefix("noise_") || kind.hasPrefix("idle_") {
                self = .count(0)
            } else if kind.hasPrefix("flick_") {
                self = .count(1)
            } else {
                return nil
            }
        }
    }

    /// Etykieta bez numeru: `flick_left_01` → `flick_left`.
    static func kind(of label: String) -> String {
        var parts = label.split(separator: "_")
        if let last = parts.last, Int(last) != nil { parts.removeLast() }
        return parts.joined(separator: "_")
    }
}

/// Wynik przepuszczenia nagrania przez recognizer.
struct FixtureResult {
    var label: String
    var expectation: FixtureExpectation
    var events: [ThrowEvent]
}

/// Ocena całego zestawu: zwraca listę błędów (pusta = wszystko zgodne).
enum FixtureJudge {
    static let directionMargin = 0.04
    static let twistSpin = 2.0

    static func failures(in results: [FixtureResult]) -> [String] {
        let centers = results.filter { $0.expectation == .center }.flatMap(\.events)
        let center = centers.isEmpty ? nil : Reference(centers)
        return results.compactMap { result in
            problem(with: result, center: center).map { "\(result.label): \($0)" }
        }
    }

    /// Opis niezgodności albo `nil`. Bez rzutów `flick_center_*` w zestawie kierunków nie sprawdzamy.
    static func problem(with result: FixtureResult, center: Reference?) -> String? {
        let events = result.events
        switch result.expectation {
        case .count(let expected):
            return events.count == expected ? nil : "oczekiwano \(expected) rzutów, jest \(events.count)"
        case .weak:
            guard events.count <= 1 else { return "słaby ruch dał \(events.count) rzuty" }
            guard let event = events.first, let center else { return nil }
            return event.speed > center.speed * 0.7 ? "słaby rzut ma prędkość \(event.speed) przy środku \(center.speed)" : nil
        default:
            guard events.count == 1 else { return "oczekiwano 1 rzutu, jest \(events.count)" }
            return directionProblem(result.expectation, event: events[0], center: center)
        }
    }

    private static func directionProblem(_ expectation: FixtureExpectation, event e: ThrowEvent, center: Reference?) -> String? {
        if expectation == .twist {
            return abs(e.spin) < twistSpin ? "rzut ze skrętem ma spin \(e.spin)" : nil
        }
        guard let c = center else { return nil }
        let m = directionMargin
        switch expectation {
        case .left: return e.yaw > c.yaw - m ? "yaw \(e.yaw) nie jest wyraźnie w lewo od środka \(c.yaw)" : nil
        case .right: return e.yaw < c.yaw + m ? "yaw \(e.yaw) nie jest wyraźnie w prawo od środka \(c.yaw)" : nil
        case .high: return e.pitch < c.pitch + m ? "pitch \(e.pitch) nie jest wyraźnie wyżej niż środek \(c.pitch)" : nil
        case .low: return e.pitch > c.pitch - m ? "pitch \(e.pitch) nie jest wyraźnie niżej niż środek \(c.pitch)" : nil
        case .strong: return e.speed < c.speed * 1.3 ? "mocny rzut ma prędkość \(e.speed) przy środku \(c.speed)" : nil
        case .jerky: return e.jerk < c.jerk * 1.5 ? "szarpnięty rzut ma jerk \(e.jerk) przy środku \(c.jerk)" : nil
        default: return nil
        }
    }

    struct Reference {
        var yaw: Double
        var pitch: Double
        var speed: Double
        var jerk: Double

        init(_ events: [ThrowEvent]) {
            let n = Double(events.count)
            yaw = events.map(\.yaw).reduce(0, +) / n
            pitch = events.map(\.pitch).reduce(0, +) / n
            speed = events.map(\.speed).reduce(0, +) / n
            jerk = events.map(\.jerk).reduce(0, +) / n
        }
    }
}

extension MotionReplayer {
    /// Rzuty z nagrania, z orientacją wziętą z metadanych (koronka od strony dłoni).
    func flickEvents(tuning: FlickTuning = FlickTuning()) -> [ThrowEvent] {
        var recognizer = FlickThrowRecognizer(
            tuning: tuning,
            orientation: WristOrientation(wrist: recording.metadata.wrist)
        )
        return events(&recognizer)
    }
}
