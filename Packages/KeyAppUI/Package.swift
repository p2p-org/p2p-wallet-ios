// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KeyAppUI",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "KeyAppUI",
            targets: ["KeyAppUI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/p2p-org/BEPureLayout.git", branch: "master"),
        // .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
        .package(url: "https://github.com/Juanpe/SkeletonView.git", from: "1.7.0")
    ],
    targets: [
        .target(
            name: "KeyAppUI",
            dependencies: [
                .product(name: "BEPureLayout", package: "BEPureLayout"),
                .product(name: "SkeletonView", package: "SkeletonView")
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "KeyAppUITests",
            dependencies: ["KeyAppUI"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
