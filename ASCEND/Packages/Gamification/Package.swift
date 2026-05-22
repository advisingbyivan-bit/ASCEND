// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Gamification",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Gamification", targets: ["Gamification"]),
    ],
    dependencies: [
        .package(name: "DesignSystem", path: "../DesignSystem"),
    ],
    targets: [
        .target(name: "Gamification", dependencies: ["DesignSystem"]),
        .testTarget(name: "GamificationTests", dependencies: ["Gamification"]),
    ]
)
