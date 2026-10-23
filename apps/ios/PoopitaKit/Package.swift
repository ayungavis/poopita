// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PoopitaKit",
    defaultLocalization: "en",
    // macOS listed only so `swift test` runs on the host without a simulator.
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "PoopitaKit", targets: ["PoopitaKit"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
    ],
    targets: [
        .target(
            name: "DesignSystem",
            resources: [.process("Resources")]
        ),
        .target(
            name: "PoopitaKit",
            dependencies: ["DesignSystem"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PoopitaKitTests",
            dependencies: ["PoopitaKit", "DesignSystem"]
        ),
    ]
)
