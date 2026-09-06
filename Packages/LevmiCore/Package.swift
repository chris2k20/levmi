// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LevmiCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "LevmiCore", targets: ["LevmiCore"])
    ],
    targets: [
        // Der Ziel-Ordner ist das Paketwurzelverzeichnis, damit `Resources/` neben `Sources/`
        // liegen kann (SPM erlaubt keine Ressourcenpfade außerhalb des Target-Verzeichnisses).
        // Kompiliert wird ausschließlich `Sources/LevmiCore`.
        .target(
            name: "LevmiCore",
            path: ".",
            exclude: ["Tests", "Package.swift"],
            sources: ["Sources/LevmiCore"],
            resources: [.copy("Resources")],
            swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]
        ),
        .testTarget(
            name: "LevmiCoreTests",
            dependencies: ["LevmiCore"],
            path: "Tests/LevmiCoreTests"
        )
    ]
)
