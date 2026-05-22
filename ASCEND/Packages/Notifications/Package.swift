// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Notifications",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Notifications", targets: ["Notifications"]),
    ],
    targets: [
        .target(name: "Notifications"),
        .testTarget(name: "NotificationsTests", dependencies: ["Notifications"]),
    ]
)
