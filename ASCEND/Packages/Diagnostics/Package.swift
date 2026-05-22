// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Diagnostics",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Diagnostics", targets: ["Diagnostics"]),
    ],
    dependencies: [
        .package(name: "DesignSystem", path: "../DesignSystem"),
        .package(name: "IRIS", path: "../IRIS"),
        .package(name: "BodyModel3D", path: "../BodyModel3D"),
        .package(name: "Networking", path: "../Networking"),
    ],
    targets: [
        .target(name: "Diagnostics", dependencies: ["DesignSystem", "IRIS", "BodyModel3D", "Networking"]),
        .testTarget(name: "DiagnosticsTests", dependencies: ["Diagnostics"]),
    ]
)
