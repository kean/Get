// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "API",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "API", targets: ["API"]),
    ],
    targets: [
        .target(name: "API", dependencies: []),
        .testTarget(name: "APITests", dependencies: ["API"], resources: [.process("Resources")]),
    ]
)
