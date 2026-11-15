// swift-tools-version: 6.0
import PackageDescription

// CieciwaCore: logika łucznictwa (balistyka, tarcza, kołysanie celownika, punktacja, wyzwanie dnia).
// Czysty Swift, bez UI i bez RealityKit: testy idą na macOS i Linuksie (`swift test`).
let package = Package(
    name: "CieciwaCore",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11),
        .macOS(.v15)
    ],
    products: [
        .library(name: "CieciwaCore", targets: ["CieciwaCore"])
    ],
    dependencies: [
        .package(path: "../../WristKit")
    ],
    targets: [
        .target(name: "CieciwaCore", dependencies: [.product(name: "WristKit", package: "WristKit")]),
        .testTarget(name: "CieciwaCoreTests", dependencies: ["CieciwaCore"])
    ],
    swiftLanguageModes: [.v6]
)
