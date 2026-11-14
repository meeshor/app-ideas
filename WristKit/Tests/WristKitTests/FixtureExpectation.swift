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
        var failures: [String] = []

        for result in results {
            let events = result.events
            func fail(_ message: String) { failures.append("\(result.label): \(message)") }
            func single() -> ThrowEvent? {
                guard events.count == 1 else {
                    fail("oczekiwano 1 rzutu, jest \(events.count)")
                    return nil
                }
                return events[0]
            }

            switch result.expectation {
            case .count(let expected):
                if events.count != expected { fail("oczekiwano \(expected) rzutów, jest \(events.count)") }
            case .center:
                _ = single()
            case .left:
                if let event = single(), let center, event.yaw > center.yaw - directionMargin {
                    fail("yaw \(event.yaw) nie jest wyraźnie w lewo od środka \(center.yaw)")
                }
            case .right:
                if let event = single(), let center, event.yaw < center.yaw + directionMargin {
                    fail("yaw \(event.yaw) nie jest wyraźnie w prawo od środka \(center.yaw)")
                }
            case .high:
                if let event = single(), let center, event.pitch < center.pitch + directionMargin {
                    fail("pitch \(event.pitch) nie jest wyraźnie wyżej niż środek \(center.pitch)")
                }
            case .low:
                if let event = single(), let center, event.pitch > center.pitch - directionMargin {
                    fail("pitch \(event.pitch) nie jest wyraźnie niżej niż środek \(center.pitch)")
                }
            case .weak:
                if events.count > 1 { fail("słaby ruch dał \(events.count) rzuty") }
                if let event = events.first, let center, event.speed > center.speed * 0.7 {
                    fail("słaby rzut ma prędkość \(event.speed) przy środku \(center.speed)")
                }
            case .strong:
                if let event = single(), let center, event.speed < center.speed * 1.3 {
                    fail("mocny rzut ma prędkość \(event.speed) przy środku \(center.speed)")
                }
            case .twist:
                if let event = single(), abs(event.spin) < twistSpin {
                    fail("rzut ze skrętem ma spin \(event.spin)")
                }
            case .jerky:
                if let event = single(), let center, event.jerk < center.jerk * 1.5 {
                    fail("szarpnięty rzut ma jerk \(event.jerk) przy środku \(center.jerk)")
                }
            }
        }
        return failures
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
