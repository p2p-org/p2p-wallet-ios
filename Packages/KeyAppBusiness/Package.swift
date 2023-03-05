// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KeyAppBusiness",
    platforms: [
        .macOS(.v12),
        .iOS(.v14),
        .tvOS(.v11),
        .watchOS(.v4),
    ],
    products: [
        .library(
            name: "KeyAppBusiness",
            targets: ["KeyAppBusiness"]),
    ],
    dependencies: [
        .package(url: "https://github.com/p2p-org/solana-swift", branch: "main"),
        .package(url: "https://github.com/p2p-org/key-app-kit-swift", branch: "master")
    ],
    targets: [
        .target(
            name: "KeyAppBusiness",
            dependencies: [
                .product(name: "SolanaSwift", package: "solana-swift"),
                .product(name: "Cache", package: "key-app-kit-swift"),
                .product(name: "SolanaPricesAPIs", package: "key-app-kit-swift"),
            ]),
        .testTarget(
            name: "KeyAppBusinessTests",
            dependencies: ["KeyAppBusiness"]),
    ]
)
