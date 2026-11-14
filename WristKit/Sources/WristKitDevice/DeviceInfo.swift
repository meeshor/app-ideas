#if os(watchOS) || os(iOS)
import Foundation
#if os(watchOS)
import WatchKit
#endif
import WristKit

public enum DeviceInfo {
    /// Identyfikator modelu, np. „Watch7,1” albo „iPhone16,2”.
    public static var modelIdentifier: String {
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: &info.machine) { buffer in
            String(decoding: buffer.prefix { $0 != 0 }, as: UTF8.self)
        }
    }

    #if os(watchOS)
    /// Na którym nadgarstku jest zegarek (Ustawienia → Ogólne → Orientacja).
    @MainActor
    public static var wrist: WristSide {
        WKInterfaceDevice.current().wristLocation == .left ? .left : .right
    }

    /// Orientacja z ustawień zegarka (nadgarstek + strona koronki).
    /// Koronka „od strony dłoni”: na lewym nadgarstku dłoń jest po prawej stronie tarczy, na prawym po lewej.
    @MainActor
    public static var orientation: WristOrientation {
        let device = WKInterfaceDevice.current()
        let wrist: WristSide = device.wristLocation == .left ? .left : .right
        let crownRight = device.crownOrientation == .right
        return WristOrientation(wrist: wrist, crownTowardHand: (wrist == .left) == crownRight)
    }
    #endif
}

#if os(watchOS)
/// Haptyka zegarka.
@MainActor
public enum Haptics {
    public static func click() { WKInterfaceDevice.current().play(.click) }
    public static func start() { WKInterfaceDevice.current().play(.start) }
    public static func stop() { WKInterfaceDevice.current().play(.stop) }
    public static func success() { WKInterfaceDevice.current().play(.success) }
    public static func failure() { WKInterfaceDevice.current().play(.failure) }
}
#endif
#endif
