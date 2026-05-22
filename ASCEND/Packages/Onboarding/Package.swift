// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Onboarding",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Onboarding", targets: ["Onboarding"]),
    ],
    dependencies: [
        .package(name: "DesignSystem", path: "../DesignSystem"),
        .package(name: "IRIS", path: "../IRIS"),
        .package(name: "BodyModel3D", path: "../BodyModel3D"),
        .package(name: "Scanner", path: "../Scanner"),
        .package(name: "Diagnostics", path: "../Diagnostics"),
        .package(name: "Paywall", path: "../Paywall"),
        .package(name: "Networking", path: "../Networking"),
    ],
    targets: [
        .target(name: "Onboarding", dependencies: ["DesignSystem", "IRIS", "BodyModel3D", "Scanner", "Diagnostics", "Paywall", "Networking"]),
        .testTarget(name: "OnboardingTests", dependencies: ["Onboarding"]),
    ]
)
