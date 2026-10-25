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
    dependencies: [
        .package(url: "https://github.com/getsentry/sentry-cocoa", exact: "8.58.4"),
    ],
    targets: [
        .target(
            name: "DesignSystem",
            resources: [.process("Resources")]
        ),
        .target(
            name: "PoopitaKit",
            dependencies: ["DesignSystem", .product(name: "Sentry", package: "sentry-cocoa")],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PoopitaKitTests",
            dependencies: ["PoopitaKit", "DesignSystem", .product(name: "Sentry", package: "sentry-cocoa")]
        ),
    ]
)
