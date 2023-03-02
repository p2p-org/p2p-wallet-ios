// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Wormhole",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v14),
        .tvOS(.v11),
        .watchOS(.v4),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Wormhole",
            targets: ["Wormhole"]),
    ],
    dependencies: [
        .package(url: "https://github.com/p2p-org/solana-swift", branch: "main"),
        .package(url: "https://github.com/Boilertalk/Web3.swift.git", from: "0.6.0"),
        .package(url: "https://github.com/trustwallet/wallet-core", branch: "master"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Wormhole",
            dependencies: [
                .product(name: "Web3", package: "Web3.swift"),
                .product(name: "Web3ContractABI", package: "Web3.swift"),
                .product(name: "SolanaSwift", package: "solana-swift"),
                .product(name: "WalletCore", package: "wallet-core"),
                .product(name: "SwiftProtobuf", package: "wallet-core"),
            ]),
        .testTarget(
            name: "WormholeTests",
            dependencies: ["Wormhole"]),
    ]
)
