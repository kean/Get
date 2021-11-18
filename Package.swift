// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "API",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "API", targets: ["API"]),
    ],
    dependencies: [
        .package(url: "https://github.com/WeTransfer/Mocker.git", .upToNextMajor(from: "2.3.0"))
    ],
    targets: [
        .target(name: "API", dependencies: []),
        .testTarget(name: "APITests", dependencies: ["API", "Mocker"], resources: [.process("Resources")]),
    ]
)
