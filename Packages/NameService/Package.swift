// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NameService",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "NameService",
            targets: ["NameService"]),
    ],
    dependencies: [
        .package(path: "../KeyAppKit"),
        .package(url: "https://github.com/p2p-org/solana-swift", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "NameService",
            dependencies: [
                .product(name: "KeyAppKitLogger", package: "KeyAppKit"),
                .product(name: "KeyAppKitCore", package: "KeyAppKit"),
                .product(name: "SolanaSwift", package: "solana-swift"),
            ]
        ),
        .testTarget(
            name: "NameServiceTests",
            dependencies: ["NameService"]),
    ]
)
