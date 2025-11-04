// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-ini-generated",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "INI", targets: ["INI"])
    ],
    targets: [
        .target(name: "INI"),
        .testTarget(name: "INITests", dependencies: ["INI"]),
    ]
)
