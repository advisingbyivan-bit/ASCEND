// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BodyModel3D",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "BodyModel3D", targets: ["BodyModel3D"]),
    ],
    dependencies: [
        .package(name: "DesignSystem", path: "../DesignSystem"),
    ],
    targets: [
        .target(
            name: "BodyModel3D",
            dependencies: ["DesignSystem"],
            resources: [
                .process("Resources/male_body.scn"),
                .process("Resources/female_body.scn"),
                .process("Resources/female_body.obj"),
                .process("Resources/female_body.usdz"),
            ]
        ),
        .testTarget(name: "BodyModel3DTests", dependencies: ["BodyModel3D"]),
    ]
)
