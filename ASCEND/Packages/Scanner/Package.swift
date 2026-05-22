// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Scanner",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Scanner", targets: ["Scanner"]),
    ],
    dependencies: [
        .package(name: "DesignSystem", path: "../DesignSystem"),
    ],
    targets: [
        .target(name: "Scanner", dependencies: ["DesignSystem"]),
        .testTarget(name: "ScannerTests", dependencies: ["Scanner"]),
    ]
)
