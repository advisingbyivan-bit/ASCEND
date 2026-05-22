// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Profile",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Profile", targets: ["Profile"]),
    ],
    targets: [
        .target(name: "Profile"),
        .testTarget(name: "ProfileTests", dependencies: ["Profile"]),
    ]
)
