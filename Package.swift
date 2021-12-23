// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Get",
    platforms: [.iOS(.v15), .macCatalyst(.v15), .macOS(.v12), .watchOS(.v8), .tvOS(.v15)],
    products: [
        .library(name: "Get", targets: ["Get"]),
    ],
    dependencies: [
        .package(url: "https://github.com/WeTransfer/Mocker.git", from: "2.3.0")
    ],
    targets: [
        .target(name: "Get"),
        .testTarget(name: "GetTests", dependencies: ["Get", "Mocker"], resources: [.process("Resources")]),
    ]
)
