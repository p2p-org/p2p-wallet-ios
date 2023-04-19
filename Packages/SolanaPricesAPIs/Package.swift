// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SolanaPricesAPIs",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SolanaPricesAPIs",
            targets: ["SolanaPricesAPIs"]),
    ],
    dependencies: [
        .package(path: "../KeyAppKit"),
    ],
    targets: [
        .target(
            name: "SolanaPricesAPIs",
            dependencies: [
                .product(name: "KeyAppKit", package: "Cache"),
                .product(name: "SolanaSwift", package: "solana-swift")
            ]
        ),
        .testTarget(
            name: "SolanaPricesAPIsUnitTests",
            dependencies: ["SolanaPricesAPIs"]
        ),
    ]
)
