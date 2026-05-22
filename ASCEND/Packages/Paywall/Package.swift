// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Paywall",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Paywall", targets: ["Paywall"]),
    ],
    dependencies: [
        .package(name: "DesignSystem", path: "../DesignSystem"),
        .package(name: "IRIS", path: "../IRIS"),
        .package(name: "Gamification", path: "../Gamification"),
    ],
    targets: [
        .target(name: "Paywall", dependencies: ["DesignSystem", "IRIS", "Gamification"]),
        .testTarget(name: "PaywallTests", dependencies: ["Paywall"]),
    ]
)
