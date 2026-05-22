// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Community",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Community", targets: ["Community"]),
    ],
    targets: [
        .target(name: "Community"),
        .testTarget(name: "CommunityTests", dependencies: ["Community"]),
    ]
)
