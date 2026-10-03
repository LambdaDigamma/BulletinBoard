// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "BLTNBoard",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "BLTNBoard", targets: ["BLTNBoard"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "BLTNBoard",
            dependencies: [],
            path: "Sources",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
                .defaultIsolation(MainActor.self),
            ]
        ),
        .testTarget(
            name: "BLTNBoardTests",
            dependencies: ["BLTNBoard"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
                .defaultIsolation(nil),
            ]
        ),
    ]
)
