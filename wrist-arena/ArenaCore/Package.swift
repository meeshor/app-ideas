// swift-tools-version: 6.0
import PackageDescription

// ArenaCore: logika modułów Wrist Arena (reguły, punktacja, tury). Czysty Swift, bez UI.
let package = Package(
    name: "ArenaCore",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11),
        .macOS(.v15)
    ],
    products: [
        .library(name: "ArenaCore", targets: ["ArenaCore"])
    ],
    dependencies: [
        .package(path: "../../WristKit")
    ],
    targets: [
        .target(name: "ArenaCore", dependencies: [.product(name: "WristKit", package: "WristKit")]),
        .testTarget(name: "ArenaCoreTests", dependencies: ["ArenaCore"])
    ],
    swiftLanguageModes: [.v6]
)
