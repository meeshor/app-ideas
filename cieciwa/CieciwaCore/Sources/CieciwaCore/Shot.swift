import Foundation
import WristKit

/// Warunki strzału (poza samym gestem).
public struct ShotConditions: Sendable, Hashable, Codable {
    /// Dystans, m.
    public var distance: Double
    public var face: TargetFace
    public var wind: Wind
    /// Tętno spoczynkowe gracza (z profilu albo HealthKit), bpm.
    public var restingHeartRate: Double?

    public init(distance: Double, face: TargetFace? = nil, wind: Wind = .calm, restingHeartRate: Double? = nil) {
        self.distance = distance
        self.face = face ?? .standard(for: distance)
        self.wind = wind
        self.restingHeartRate = restingHeartRate
    }
}

/// Wskazówka po strzale (jedna, najważniejsza).
public enum ShotHint: String, Sendable, Hashable, Codable, CaseIterable {
    case weakDraw
    case earlyRelease
    case heldTooLong
    case shakyHand
    case calmDown
    case wind
    case good

    public var text: String {
        switch self {
        case .weakDraw: "Za słaby naciąg — strzała opadła. Dociągnij do kotwicy."
        case .earlyRelease: "Puściłeś za wcześnie. Daj ręce 2 sekundy w kotwicy."
        case .heldTooLong: "Za długo trzymałeś — ręka się męczy. Strzelaj w 2–4 s."
        case .shakyHand: "Ręka drżała w kotwicy. Oprzyj kciuk o żuchwę i rozluźnij palce."
        case .calmDown: "Tętno wysoko. Weź dwa spokojne oddechy przed strzałem."
        case .wind: "Wiatr zniósł strzałę. Przesuń celownik pod wiatr."
        case .good: "Czysty strzał. Tak trzymaj."
        }
    }
}

/// Rozstrzygnięty strzał.
public struct ArrowResult: Sendable, Hashable, Codable {
    /// Punkt trafienia względem środka tarczy, cm (x w prawo, y w górę).
    public var x: Double
    public var y: Double
    public var score: ArrowScore
    public var flightTime: Double
    public var speed: Double
    /// Amplituda kołysania w chwili strzału, mrad.
    public var sway: Double
    public var hint: ShotHint
    public var release: ShotRelease
}

/// Strzał: celowanie (telefon), kołysanie (zegarek), balistyka, punktacja, wskazówka.
public struct ShotResolver: Sendable, Hashable {
    public var ballistics: Ballistics
    public var sway: SwayModel

    public init(ballistics: Ballistics = Ballistics(), sway: SwayModel = SwayModel()) {
        self.ballistics = ballistics
        self.sway = sway
    }

    /// - Parameters:
    ///   - aim: kierunek celowania telefonem względem środka tarczy po kalibracji, rad (yaw w prawo, pitch w górę).
    ///   - seed: ziarno kołysania (to samo, którym rysowano celownik na żywo).
    public func resolve<G: RandomNumberGenerator>(
        aim: (yaw: Double, pitch: Double),
        release: ShotRelease,
        conditions: ShotConditions,
        seed: UInt64,
        using rng: inout G
    ) -> ArrowResult {
        let amplitude = sway.amplitude(
            stability: release.stability,
            heartRate: release.heartRate,
            restingHeartRate: conditions.restingHeartRate,
            holdTime: release.holdTime
        )
        let wobble = sway.offset(at: release.holdTime, amplitude: amplitude, seed: seed)
        let noise = sway.tuning.releaseNoise
        let yaw = aim.yaw + (wobble.x + rng.nextGaussian() * noise) / 1000
        let pitch = aim.pitch + (wobble.y + rng.nextGaussian() * noise) / 1000

        let speed = ballistics.bow.speed(strength: release.strength)
        let sight = ballistics.sightElevation(distance: conditions.distance)
        let flight = ballistics.fly(
            speed: speed,
            elevation: sight + pitch,
            yaw: yaw,
            wind: conditions.wind,
            distance: conditions.distance
        )
        let x = flight.x * 100, y = flight.y * 100
        let score = conditions.face.score(x: x, y: y)

        // Ile wiatr zniósł strzałę (cm) — porównanie z lotem bez wiatru.
        let calm = ballistics.fly(speed: speed, elevation: sight + pitch, yaw: yaw, wind: .calm, distance: conditions.distance)
        let windDrift = abs(flight.x - calm.x) * 100
        let hint = Self.hint(
            release: release,
            amplitude: amplitude,
            baseAmplitude: sway.tuning.base,
            restingHeartRate: conditions.restingHeartRate ?? sway.tuning.defaultRestingHeartRate,
            idealHold: sway.tuning.idealHold,
            windDrift: windDrift,
            ringWidth: conditions.face.ringWidth
        )
        return ArrowResult(x: x, y: y, score: score, flightTime: flight.time, speed: speed, sway: amplitude, hint: hint, release: release)
    }

    /// Najważniejsza wskazówka (kolejność = waga błędu).
    static func hint(
        release: ShotRelease,
        amplitude: Double,
        baseAmplitude: Double,
        restingHeartRate: Double,
        idealHold: ClosedRange<Double>,
        windDrift: Double,
        ringWidth: Double
    ) -> ShotHint {
        if release.strength < 0.7 { return .weakDraw }
        if release.holdTime < idealHold.lowerBound * 0.6 { return .earlyRelease }
        if release.stability > 0.15 { return .shakyHand }
        if let hr = release.heartRate, hr - restingHeartRate > 30 { return .calmDown }
        if release.holdTime > idealHold.upperBound + 2 { return .heldTooLong }
        if windDrift > ringWidth * 1.5 { return .wind }
        return .good
    }
}
