// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "History",
    platforms: [
        .macOS(.v12),
        .iOS(.v14),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "History",
            targets: ["History"]),
    ],
    dependencies: [
        .package(path: "../Onboarding"),
        .package(url: "https://github.com/p2p-org/solana-swift", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "History",
            dependencies: [
                "Onboarding",
                .product(name: "SolanaSwift", package: "solana-swift"),
            ]
        ),
        .testTarget(
            name: "HistoryTests",
            dependencies: ["History"]),
    ]
)
