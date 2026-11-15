import Foundation
import Observation
import WristKit

/// Kalibracja gracza „3 rzuty w środek” z zegarka (albo symulowanych rzutów).
@MainActor
@Observable
final class CalibrationModel {
    private(set) var profile: PlayerProfile
    private(set) var session = CalibrationSession()
    private(set) var message: String
    private(set) var result: Calibration?

    @ObservationIgnored private let hub = PhoneLink.shared
    @ObservationIgnored private let handlerKey = "calibration"

    init(profile: PlayerProfile) {
        self.profile = profile
        self.message = "Rzuć \(CalibrationSession().requiredThrows) razy, celując w środek tarczy."
    }

    var thrown: Int { session.directions.count }
    var required: Int { session.requiredThrows }
    var isDone: Bool { result != nil }

    func start() {
        hub.activate()
        hub.addMessageHandler(handlerKey) { [weak self] message, _ in
            guard case .throwEvent(let event) = message.payload else { return }
            self?.add(event)
        }
        hub.send(.control(.updateTuning(TuningStore.shared.gesture)))
        hub.send(.control(.startSession(kind: .flick)))
        hub.send(.control(.setActivePlayer(name: profile.name, wrist: profile.wrist)))
    }

    func stop() {
        hub.removeMessageHandler(handlerKey)
    }

    func simulateThrow() {
        let tuning = TuningStore.shared.gesture.flick
        guard let event = ThrowSimulator.throwEvent(wrist: profile.wrist, skill: 0.9, tuning: tuning) else { return }
        add(event)
    }

    func restart() {
        session.reset()
        result = nil
        message = "Rzuć \(session.requiredThrows) razy, celując w środek tarczy."
    }

    /// Profil z zapisaną kalibracją (po zakończeniu).
    var calibratedProfile: PlayerProfile? {
        guard let result else { return nil }
        var updated = profile
        updated.calibrations[.flick] = result
        return updated
    }

    private func add(_ event: ThrowEvent) {
        guard result == nil else { return }
        switch session.add(event) {
        case .needMore(let remaining):
            message = remaining == 1 ? "Jeszcze 1 rzut." : "Jeszcze \(remaining) rzuty."
        case .inconsistent:
            message = "Rzuty bardzo się różniły. Spróbuj rzucać za każdym razem tak samo. Od nowa."
        case .done(let calibration):
            result = calibration
            message = "Gotowe. Twój „środek” jest zapisany."
        }
    }
}
