// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "IRIS",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "IRIS", targets: ["IRIS"]),
    ],
    dependencies: [
        .package(name: "DesignSystem", path: "../DesignSystem"),
    ],
    targets: [
        .target(name: "IRIS", dependencies: ["DesignSystem"]),
        .testTarget(name: "IRISTests", dependencies: ["IRIS"]),
    ]
)
