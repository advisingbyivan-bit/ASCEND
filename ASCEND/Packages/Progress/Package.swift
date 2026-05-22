// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Progress",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Progress", targets: ["Progress"]),
    ],
    targets: [
        .target(name: "Progress"),
        .testTarget(name: "ProgressTests", dependencies: ["Progress"]),
    ]
)
