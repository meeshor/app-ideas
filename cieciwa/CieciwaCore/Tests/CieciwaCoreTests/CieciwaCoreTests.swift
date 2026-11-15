import Foundation
import Testing
import WristKit
@testable import CieciwaCore

@Suite("Tarcza")
struct TargetTests {
    let face = TargetFace.indoor40 // pierścień 2 cm

    @Test func ringsAndLines() {
        #expect(face.score(x: 0, y: 0) == ArrowScore(value: 10, isX: true))
        #expect(face.score(x: 1.5, y: 0) == ArrowScore(value: 10, isX: false))
        #expect(face.score(x: 2.0, y: 0).value == 10, "strzała na linii liczy się wyżej")
        #expect(face.score(x: 2.01, y: 0).value == 9)
        #expect(face.score(x: 0, y: -19.9).value == 1)
        #expect(face.score(x: 15, y: 15).value == 0)
        #expect(ArrowScore(value: 0, isX: false).label == "M")
        #expect(TargetFace.standard(for: 18) == .indoor40)
        #expect(TargetFace.standard(for: 70) == .outdoor122)
    }
}

@Suite("Balistyka")
struct BallisticsTests {
    let ballistics = Ballistics()

    @Test func sightZeroesFullDraw() {
        for distance in [18.0, 30.0, 50.0, 70.0] {
            let sight = ballistics.sightElevation(distance: distance)
            let flight = ballistics.fly(speed: ballistics.bow.speed(strength: 1), elevation: sight, yaw: 0, wind: .calm, distance: distance)
            #expect(abs(flight.y) < 0.001)
            #expect(abs(flight.x) < 1e-9)
            // Czas lotu ≈ dystans / prędkość (opór wydłuża lot o kilka %).
            let naive = distance / ballistics.bow.maxSpeed
            #expect(flight.time > naive && flight.time < naive * 1.15)
        }
        #expect(ballistics.sightElevation(distance: 70) > ballistics.sightElevation(distance: 18))
    }

    @Test func weakDrawDropsAndWindDrifts() {
        let sight = ballistics.sightElevation(distance: 30)
        let weak = ballistics.fly(speed: ballistics.bow.speed(strength: 0.6), elevation: sight, yaw: 0, wind: .calm, distance: 30)
        #expect(weak.y < -0.1, "słabszy naciąg: strzała ląduje kilkanaście cm niżej")
        let windy = ballistics.fly(speed: ballistics.bow.speed(strength: 1), elevation: sight, yaw: 0, wind: Wind(cross: 4), distance: 30)
        #expect(windy.x > 0.01 && windy.x < 0.3, "boczny wiatr 4 m/s znosi o kilka cm na 30 m")
        let headwind = ballistics.fly(speed: ballistics.bow.speed(strength: 1), elevation: sight, yaw: 0, wind: Wind(head: 5), distance: 30)
        #expect(headwind.y < 0, "wiatr w twarz: większy opór, strzała niżej")
    }

    @Test func dragSlowsTheArrow() {
        let flight = ballistics.fly(speed: 58, elevation: 0.02, yaw: 0, wind: .calm, distance: 70)
        #expect(flight.impactSpeed < 58 * 0.95)
        #expect(flight.impactSpeed > 58 * 0.7)
    }
}

@Suite("Kołysanie i strzał")
struct SwayShotTests {
    let sway = SwayModel()

    @Test func amplitudeGrowsWithShakingHeartRateAndFatigue() {
        let ideal = sway.amplitude(stability: 0.02, heartRate: 70, holdTime: 3)
        #expect(sway.amplitude(stability: 0.2, heartRate: 70, holdTime: 3) > ideal * 2)
        #expect(sway.amplitude(stability: 0.02, heartRate: 120, holdTime: 3) > ideal * 1.5)
        #expect(sway.amplitude(stability: 0.02, heartRate: 70, holdTime: 8) > ideal * 2)
        #expect(sway.amplitude(stability: 0.02, heartRate: 70, holdTime: 0.5) > ideal)
        #expect(sway.amplitude(stability: 0.02, heartRate: nil, holdTime: 3) == sway.amplitude(stability: 0.02, heartRate: 70, holdTime: 3))
    }

    @Test func offsetIsDeterministicBoundedAndMoves() {
        let a = sway.offset(at: 1.5, amplitude: 2, seed: 7)
        let b = sway.offset(at: 1.5, amplitude: 2, seed: 7)
        #expect(a.x == b.x && a.y == b.y)
        var maxR = 0.0
        for i in 0..<200 {
            let o = sway.offset(at: Double(i) * 0.05, amplitude: 2, seed: 7)
            maxR = max(maxR, (o.x * o.x + o.y * o.y).squareRoot())
        }
        #expect(maxR <= 2 * 1.42 && maxR > 0.5)
    }

    private func averageScore(stability: Double, holdTime: Double, strength: Double = 1, distance: Double = 18) -> Double {
        let resolver = ShotResolver()
        var rng = SeededRandom(seed: 1)
        var total = 0
        for seed in UInt64(0)..<100 {
            let release = ShotRelease(strength: strength, stability: stability, holdTime: holdTime, watchTimestamp: 0)
            total += resolver.resolve(aim: (0, 0), release: release, conditions: ShotConditions(distance: distance), seed: seed, using: &rng)
                .score.value
        }
        return Double(total) / 100
    }

    @Test func steadyShotsScoreHighShakyLower() {
        let steady = averageScore(stability: 0.02, holdTime: 3)
        let shaky = averageScore(stability: 0.25, holdTime: 3)
        let weak = averageScore(stability: 0.02, holdTime: 3, strength: 0.6)
        #expect(steady > 8.5)
        #expect(shaky < steady - 1)
        #expect(weak < steady - 3)
    }

    @Test func hintsPickTheMainProblem() {
        func hint(strength: Double = 1, stability: Double = 0.02, hold: Double = 3, hr: Double? = nil, drift: Double = 0) -> ShotHint {
            ShotResolver.hint(
                release: ShotRelease(strength: strength, stability: stability, holdTime: hold, heartRate: hr, watchTimestamp: 0),
                amplitude: 1, baseAmplitude: 1, restingHeartRate: 70, idealHold: 2...4, windDrift: drift, ringWidth: 2
            )
        }
        #expect(hint() == .good)
        #expect(hint(strength: 0.5) == .weakDraw)
        #expect(hint(hold: 0.8) == .earlyRelease)
        #expect(hint(stability: 0.3) == .shakyHand)
        #expect(hint(hr: 130) == .calmDown)
        #expect(hint(hold: 9) == .heldTooLong)
        #expect(hint(drift: 5) == .wind)
        #expect(ShotHint.allCases.allSatisfy { !$0.text.isEmpty })
    }
}

@Suite("Runda, rekordy, wyzwanie dnia")
struct RoundTests {
    private func arrow(_ value: Int) -> ArrowResult {
        ArrowResult(
            x: 0, y: 0, score: ArrowScore(value: value, isX: value == 10), flightTime: 0.3, speed: 58, sway: 1, hint: .good,
            release: ShotRelease(strength: 1, stability: 0, holdTime: 3, watchTimestamp: 0)
        )
    }

    @Test func endsTotalsAndRecords() {
        var round = ArcheryRound(conditions: ShotConditions(distance: 18), arrowsPerEnd: 3, ends: 2)
        for value in [10, 9, 8, 7, 10, 6] { round.add(arrow(value)) }
        #expect(round.isComplete)
        let extra = round.add(arrow(10))
        #expect(!extra)
        #expect(round.total == 50)
        #expect(round.xCount == 2)
        #expect(round.endScores.map { $0.map(\.value) } == [[10, 9, 8], [7, 10, 6]])

        var bests = PersonalBests()
        let first = bests.submit(round)
        let same = bests.submit(round)
        #expect(first)
        #expect(!same, "ten sam wynik to nie rekord")
        round.undo()
        round.add(arrow(10))
        let better = bests.submit(round)
        #expect(better)
        #expect(bests.best(distance: 18, arrows: 6)?.total == 54)
    }

    @Test func dailyChallengeIsStableAndVaries() {
        let a = DailyChallenge(year: 2026, month: 11, day: 15)
        let b = DailyChallenge(year: 2026, month: 11, day: 15)
        #expect(a == b)
        #expect(a.id == "2026-11-15")
        let days = (1...28).map { DailyChallenge(year: 2026, month: 2, day: $0) }
        #expect(Set(days.map(\.distance)).count > 1)
        #expect(Set(days.map(\.swaySeed)).count == 28)
        #expect(days.filter { $0.distance < 25 }.allSatisfy { $0.wind == .calm })
        #expect(days.allSatisfy { $0.wind.speed <= 6.0001 })
        #expect(a.swaySeed(arrow: 0) != a.swaySeed(arrow: 1))
    }
}

/// Ruch ręki z zegarkiem → DrawReleaseRecognizer → strzał → punkty.
@Suite("Od naciągu do punktów")
struct EndToEndTests {
    private func release(tremor: Double, seed: UInt64) throws -> ShotRelease {
        var motion = SyntheticMotion(elevation: -1.2, seed: seed)
        motion.hold(0.5)
        motion.raiseArm()
        motion.hold(0.4)
        motion.draw()
        motion.anchor(0.4)
        motion.anchor(2.6, tremor: tremor)
        motion.release()
        motion.hold(1)
        var recognizer = DrawReleaseRecognizer()
        let events = MotionReplayer(recording: motion.recording(label: "e2e")).events(&recognizer)
        let shot = events.compactMap { if case .released(let shot) = $0 { shot } else { nil } }.first
        return try #require(shot)
    }

    @Test func steadyHandBeatsShakyHand() throws {
        let resolver = ShotResolver()
        var rng = SeededRandom(seed: 3)
        var steady = 0, shaky = 0
        for seed in UInt64(1)...12 {
            let conditions = ShotConditions(distance: 18)
            steady += resolver.resolve(aim: (0, 0), release: try release(tremor: 0.02, seed: seed), conditions: conditions, seed: seed, using: &rng)
                .score.value
            shaky += resolver.resolve(aim: (0, 0), release: try release(tremor: 0.2, seed: seed), conditions: conditions, seed: seed, using: &rng)
                .score.value
        }
        #expect(steady > shaky)
        #expect(steady >= 12 * 8)
    }
}
