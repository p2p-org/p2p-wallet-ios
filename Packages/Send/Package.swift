// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Send",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Send",
            targets: ["Send"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Send",
            dependencies: [
                .product(name: "SolanaSwift", package: "solana-swift"),
                .product(name: "FeeRelayerSwift", package: "FeeRelayerSwift"),
                "NameService",
                "SolanaPricesAPIs",
                "TransactionParser",
                "History",
                "Wormhole",
            ]
        ),
        
            .testTarget(
                name: "SendTest",
                dependencies: ["Send"],
                path: "Tests/UnitTests/SendTests"
            ),
    ]
)
