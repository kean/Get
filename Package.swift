// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Get",
    platforms: [.iOS(.v13), .macCatalyst(.v13), .macOS(.v10_15), .watchOS(.v6), .tvOS(.v13)],
    products: [
        .library(name: "Get", targets: ["Get"])
    ],
    targets: [
        .target(name: "Get"),
        .testTarget(name: "GetTests", dependencies: ["Get"], resources: [.process("Resources")])
    ]
)
