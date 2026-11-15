import Foundation

/// Generator syntetycznego ruchu ręki z zegarkiem.
///
/// Po co: symulator nie ma czujników, a prawdziwych nagrań jest mało. Generator daje
/// powtarzalne próbki o znanym „prawdziwym” kierunku rzutu: testy recognizerów,
/// przycisk „symulowany rzut” w aplikacji i podgląd w ekranie debug.
///
/// Model: orientacja całkowana z prędkości kątowej zadanej w układzie świata (Z w górę),
/// dłoń na końcu przedramienia o długości `leverArm` (przyspieszenie = α×p + ω×(ω×p)).
/// To uproszczenie (łokieć nieruchomy), więc progi i tak trzeba stroić na prawdziwych
/// nagraniach. Konwencja kwaternionu: `attitude` obraca wektor z układu urządzenia do świata.
public struct SyntheticMotion: Sendable {
    public var sampleRate: Double = 100
    public var orientation: WristOrientation
    /// Długość przedramienia, m.
    public var leverArm: Double = 0.35
    /// Drżenie ręki w spoczynku: odchylenie prędkości kątowej, rad/s.
    public var tremor: Double = 0.02
    /// Szum przyspieszenia, g.
    public var accelerationNoise: Double = 0.01

    public private(set) var samples: [MotionSample] = []
    public private(set) var attitude: Quaternion
    public private(set) var t: TimeInterval

    private var rng: SeededRandom
    private var previousWorldRate = Vector3.zero
    /// Drżenie jako wygładzony szum (AR(1)): biały szum w ω dawałby nierealnie duże α.
    private var tremorState = Vector3.zero

    static let worldUp = Vector3(0, 0, 1)
    static let standardGravity = 9.81

    public init(
        orientation: WristOrientation = WristOrientation(),
        heading: Double = 0,
        elevation: Double = 0.9,
        roll: Double = 0,
        seed: UInt64 = 1,
        startTime: TimeInterval = 1000
    ) {
        self.orientation = orientation
        self.attitude = Self.pose(heading: heading, elevation: elevation, roll: roll, orientation: orientation)
        self.rng = SeededRandom(seed: seed)
        self.t = startTime
    }

    /// Orientacja, w której oś dłoni ma zadany kierunek (heading: obrót w lewo wokół pionu,
    /// elevation: wzniesienie nad poziom), a `roll` obraca zegarek wokół przedramienia.
    public static func pose(heading: Double, elevation: Double, roll: Double, orientation: WristOrientation) -> Quaternion {
        // Bazowo oś dłoni = +x świata. Dla dłoni w −x najpierw obracamy urządzenie o 180° wokół z.
        let flip = orientation.handAxis.x < 0 ? Quaternion(axis: Vector3(0, 0, 1), angle: .pi) : .identity
        return Quaternion(axis: worldUp, angle: heading)
            * Quaternion(axis: Vector3(0, 1, 0), angle: -elevation)
            * Quaternion(axis: Vector3(1, 0, 0), angle: roll)
            * flip
    }

    /// Kierunek dłoni w układzie świata.
    public var handDirection: Vector3 { attitude.act(on: orientation.handAxis) }

    /// Oś „w prawo” płaszczyzny rzutu (pozioma, prostopadła do kierunku dłoni).
    public var rightAxis: Vector3 {
        let h = handDirection
        let horizontal = Vector3(h.x, h.y, 0)
        let forward = horizontal.length > 1e-6 ? horizontal.normalized : Vector3(1, 0, 0)
        return forward.cross(Self.worldUp)
    }

    // MARK: - Ruchy podstawowe

    /// Ręka nieruchoma (z drżeniem).
    public mutating func hold(_ duration: TimeInterval) {
        move(duration) { _, _ in .zero }
    }

    /// Ruch zadany prędkością kątową w układzie świata jako funkcją postępu τ ∈ [0, 1)
    /// i bieżącej symulacji (np. do obrotu wokół aktualnej osi dłoni).
    public mutating func move(_ duration: TimeInterval, worldRate: (Double, SyntheticMotion) -> Vector3) {
        move(duration, worldRate: worldRate) { _, _ in .zero }
    }

    /// Ruch z dodatkowym przyspieszeniem liniowym całej ręki (w g, układ świata),
    /// np. naciąg cięciwy: dłoń jedzie w tył wzdłuż przedramienia bez obrotu.
    public mutating func move(
        _ duration: TimeInterval,
        worldRate: (Double, SyntheticMotion) -> Vector3,
        linear: (Double, SyntheticMotion) -> Vector3
    ) {
        let dt = 1 / sampleRate
        let steps = max(1, Int((duration * sampleRate).rounded()))
        for step in 0..<steps {
            let tau = Double(step) / Double(steps)
            let kick = Vector3(rng.nextGaussian(), rng.nextGaussian(), rng.nextGaussian()) * (tremor * 0.2)
            tremorState = tremorState * 0.98 + kick
            emit(worldRate: worldRate(tau, self) + tremorState, linear: linear(tau, self), dt: dt)
        }
    }

    private mutating func emit(worldRate omega: Vector3, linear extra: Vector3 = .zero, dt: Double) {
        let alpha = (omega - previousWorldRate) / dt
        previousWorldRate = omega
        let hand = handDirection * leverArm
        let linear = alpha.cross(hand) + omega.cross(omega.cross(hand)) + extra * Self.standardGravity
        let noise = Vector3(rng.nextGaussian(), rng.nextGaussian(), rng.nextGaussian()) * accelerationNoise
        let inverse = attitude.inverse
        samples.append(MotionSample(
            t: t,
            attitude: attitude,
            rotationRate: inverse.act(on: omega),
            userAcceleration: inverse.act(on: linear) / Self.standardGravity + noise,
            gravity: inverse.act(on: Vector3(0, 0, -1))
        ))
        let angle = omega.length * dt
        if angle > 0 {
            attitude = (Quaternion(axis: omega, angle: angle) * attitude).normalized
        }
        t += dt
    }

    /// Kształt sin²: 0 na brzegach, 1 w środku; całka po τ ∈ [0, 1] = 1/2.
    static func bell(_ tau: Double) -> Double {
        let s = sin(.pi * tau)
        return s * s
    }

    // MARK: - Gesty

    /// Parametry syntetycznego rzutu z nadgarstka.
    public struct Flick: Sendable, Hashable {
        /// Szczyt prędkości kątowej zamachu w przód, rad/s.
        public var peakRate: Double = 12
        /// Czas właściwego rzutu, s.
        public var duration: TimeInterval = 0.18
        /// Krótki zamach w tył przed rzutem.
        public var backswing = true
        /// Odchylenie w prawo osiągnięte w chwili szczytu, rad.
        public var yawDeviation: Double = 0
        /// Odchylenie w górę osiągnięte w chwili szczytu, rad.
        public var pitchDeviation: Double = 0
        /// Rotacja wokół przedramienia (szczyt), rad/s; dodatnia = supinacja prawej ręki.
        public var spinRate: Double = 0
        /// 0…1: drgania 25 Hz nałożone na rzut (szarpnięcie).
        public var jerkiness: Double = 0

        public init(
            peakRate: Double = 12,
            duration: TimeInterval = 0.18,
            backswing: Bool = true,
            yawDeviation: Double = 0,
            pitchDeviation: Double = 0,
            spinRate: Double = 0,
            jerkiness: Double = 0
        ) {
            self.peakRate = peakRate
            self.duration = duration
            self.backswing = backswing
            self.yawDeviation = yawDeviation
            self.pitchDeviation = pitchDeviation
            self.spinRate = spinRate
            self.jerkiness = jerkiness
        }
    }

    /// Rzut z nadgarstka: (zamach w tył) → zamach w przód w pionowej płaszczyźnie dłoni.
    /// Płaszczyzna zamachu obraca się razem z dłonią, więc odchylenie w bok osiągnięte w chwili
    /// szczytu wynosi dokładnie `yawDeviation`.
    public mutating func flick(_ spec: Flick) {
        if spec.backswing {
            move(0.2) { tau, sim in sim.rightAxis * (3 * Self.bell(tau)) }
        }
        // Do szczytu (τ = 0,5) całka kształtu sin² wynosi duration/4.
        let yawRate = 4 * spec.yawDeviation / spec.duration
        let pitchRate = 4 * spec.pitchDeviation / spec.duration
        let spinSign = orientation.wrist.mirrorSign
        let duration = spec.duration
        move(duration) { tau, sim in
            let shape = Self.bell(tau)
            let wobble = 1 + spec.jerkiness * sin(2 * .pi * 25 * tau * duration)
            let right = sim.rightAxis
            let sweep = right * (-spec.peakRate * shape * wobble)
            let aim = Self.worldUp * (-yawRate * shape) + right * (pitchRate * shape)
            let spin = sim.handDirection * (spec.spinRate * spinSign * shape)
            return sweep + aim + spin
        }
    }

    /// Parametry rzutu z zamachem nad głową (piłka ręczna).
    public struct Overarm: Sendable, Hashable {
        /// Szczyt |ω| zamachu w tył, rad/s.
        public var windupRate: Double = 5
        /// Szczyt |ω| rzutu w przód, rad/s.
        public var peakRate: Double = 16
        /// Czas rzutu w przód, s.
        public var duration: TimeInterval = 0.22
        public var yawDeviation: Double = 0
        public var pitchDeviation: Double = 0
        /// Rotacja przedramienia („wkrętka”), rad/s; dodatnia = supinacja.
        public var spinRate: Double = 0

        public init(
            windupRate: Double = 5,
            peakRate: Double = 16,
            duration: TimeInterval = 0.22,
            yawDeviation: Double = 0,
            pitchDeviation: Double = 0,
            spinRate: Double = 0
        ) {
            self.windupRate = windupRate
            self.peakRate = peakRate
            self.duration = duration
            self.yawDeviation = yawDeviation
            self.pitchDeviation = pitchDeviation
            self.spinRate = spinRate
        }
    }

    /// Zamach w tył (ręka idzie za głowę), bez pauzy przechodzi w rzut w przód.
    public mutating func overarm(_ spec: Overarm) {
        // Stała płaszczyzna zamachu: przy ręce za głową pozioma oś dłoni zmienia zwrot.
        let right = rightAxis
        move(0.3) { tau, _ in right * (spec.windupRate * Self.bell(tau)) }
        // Rzut w bok = cała płaszczyzna rzutu obrócona o yawDeviation (ręka startuje prawie pionowo,
        // więc obrót wokół pionu niewiele by zmienił).
        let thrownRight = Quaternion(axis: Self.worldUp, angle: -spec.yawDeviation).act(on: right)
        let pitchRate = 4 * spec.pitchDeviation / spec.duration
        let spinSign = orientation.wrist.mirrorSign
        move(spec.duration) { tau, sim in
            let shape = Self.bell(tau)
            return thrownRight * (-spec.peakRate * shape + pitchRate * shape)
                + sim.handDirection * (spec.spinRate * spinSign * shape)
        }
    }

    /// Zwód: zamach w tył i początek ruchu w przód, zatrzymany przed rzutem.
    public mutating func feint(windupRate: Double = 5, forwardRate: Double = 4) {
        let right = rightAxis
        move(0.3) { tau, _ in right * (windupRate * Self.bell(tau)) }
        move(0.2) { tau, _ in right * (-forwardRate * Self.bell(tau)) }
    }

    // MARK: - Łucznictwo (ręka naciągająca)

    /// Uniesienie ręki z opuszczonej do poziomu (przedramię wskazuje przód).
    public mutating func raiseArm(from elevation: Double = -1.2, duration: TimeInterval = 0.8) {
        let right = rightAxis
        let rate = 2 * (0 - elevation) / duration
        move(duration) { tau, _ in right * (rate * Self.bell(tau)) }
    }

    /// Naciąg: dłoń przyspiesza w tył wzdłuż przedramienia, potem hamuje przy kotwicy.
    /// `peakAcceleration` w g; impuls fazy przyspieszania = peak · duration / π.
    public mutating func draw(peakAcceleration: Double = 0.3, duration: TimeInterval = 1.2) {
        let back = -handDirection
        move(duration, worldRate: { _, _ in .zero }) { tau, _ in
            back * (peakAcceleration * sin(2 * .pi * tau))
        }
    }

    /// Kotwica: ręka nieruchoma z zadanym drżeniem (rad/s).
    public mutating func anchor(_ duration: TimeInterval, tremor shake: Double = 0.03) {
        let saved = tremor
        tremor = shake
        hold(duration)
        tremor = saved
    }

    /// Puszczenie cięciwy: dłoń odskakuje w tył (szarpnięcie liniowe i obrót nadgarstka).
    public mutating func release(strength: Double = 1) {
        let back = -handDirection
        let right = rightAxis
        move(0.08, worldRate: { tau, _ in right * (6 * strength * Self.bell(tau)) }) { tau, _ in
            back * (2.5 * strength * Self.bell(tau))
        }
    }

    /// Machanie na „cześć”: oscylacja wokół osi przód–tył.
    public mutating func wave(cycles: Int = 3, frequency: Double = 2, peakRate: Double = 7) {
        let axis = rightAxis.cross(Self.worldUp)
        let duration = Double(cycles) / frequency
        move(duration) { tau, _ in axis * (peakRate * sin(2 * .pi * Double(cycles) * tau)) }
    }

    /// Drapanie się: szybkie, krótkie ruchy tam i z powrotem.
    public mutating func scratch(duration: TimeInterval = 1, frequency: Double = 4, peakRate: Double = 6) {
        let axis = (rightAxis + Self.worldUp * 0.5).normalized
        let cycles = duration * frequency
        move(duration) { tau, _ in axis * (peakRate * sin(2 * .pi * cycles * tau)) }
    }

    /// Powolne opuszczenie ręki wzdłuż ciała.
    public mutating func lowerArm(duration: TimeInterval = 1.5, angle: Double = 2) {
        let right = rightAxis
        let peak = 2 * angle / duration
        move(duration) { tau, _ in right * (-peak * Self.bell(tau)) }
    }

    /// Sam obrót przedramienia (jak przekręcenie klucza), bez rzutu.
    public mutating func twist(duration: TimeInterval = 0.3, peakRate: Double = 10) {
        move(duration) { tau, sim in sim.handDirection * (peakRate * Self.bell(tau)) }
    }

    /// Nagranie z wygenerowanych próbek.
    public func recording(label: String, notes: String = "syntetyczne") -> MotionRecording {
        MotionRecording(
            metadata: .init(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000000") ?? UUID(),
                createdAt: Date(timeIntervalSince1970: 1_800_000_000),
                label: label,
                wrist: orientation.wrist,
                device: "synthetic",
                sampleRate: sampleRate,
                notes: notes
            ),
            samples: samples
        )
    }
}
