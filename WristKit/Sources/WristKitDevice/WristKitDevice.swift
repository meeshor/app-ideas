import WristKit

// Warstwa sprzętowa: Core Motion, HealthKit (HKWorkoutSession), WatchConnectivity, haptyka.
//
// Uwaga: `#if canImport(CoreMotion)` NIE wystarcza, bo CoreMotion istnieje na macOS,
// a `CMMotionManager` jest tam niedostępny. Dlatego warunek po systemie.
// Na macOS (CI, `swift test`) ten moduł jest pusty poza `WristKitDeviceInfo`.

public enum WristKitDeviceInfo {
    #if os(watchOS) || os(iOS)
    public static let isSupported = true
    #else
    public static let isSupported = false
    #endif
}

// Implementacje (LiveMotionSource, WorkoutSessionController, WatchLink, Haptics) dochodzą w M1.
