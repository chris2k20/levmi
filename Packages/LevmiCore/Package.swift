// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LevmiCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "LevmiCore", targets: ["LevmiCore"])
    ],
    targets: [
        .target(
            name: "LevmiCore",
            swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]
        ),
        .testTarget(
            name: "LevmiCoreTests",
            dependencies: ["LevmiCore"]
        )
    ]
)
