// swift-tools-version: 6.0
import PackageDescription

// WristKit: wspólny silnik ruchu i gestów z Apple Watch.
// Używają go Wrist Arena, Cięciwa i Slingworks, więc nie zależy od żadnej gry.
//
// - `WristKit`: czysty Swift (sam Foundation). Próbki, nagrania, rozpoznawanie gestów,
//   zdarzenia, profile. Kompiluje się i testuje na macOS (`swift test`) bez symulatora.
// - `WristKitDevice`: Core Motion, HealthKit, WatchConnectivity. Kod tylko pod
//   `#if os(watchOS) || os(iOS)`, więc na macOS moduł jest pusty.
let package = Package(
    name: "WristKit",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11),
        .macOS(.v15)
    ],
    products: [
        .library(name: "WristKit", targets: ["WristKit"]),
        .library(name: "WristKitDevice", targets: ["WristKitDevice"])
    ],
    targets: [
        .target(name: "WristKit"),
        .target(name: "WristKitDevice", dependencies: ["WristKit"]),
        .testTarget(name: "WristKitTests", dependencies: ["WristKit"])
    ],
    swiftLanguageModes: [.v6]
)
