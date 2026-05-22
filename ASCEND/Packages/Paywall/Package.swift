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
        .package(url: "https://github.com/RevenueCat/purchases-ios-spm.git", from: "5.21.0"),
    ],
    targets: [
        .target(name: "Paywall", dependencies: [
            "DesignSystem",
            "IRIS",
            "Gamification",
            .product(name: "RevenueCat", package: "purchases-ios-spm"),
        ]),
        .testTarget(name: "PaywallTests", dependencies: ["Paywall"]),
    ]
)
