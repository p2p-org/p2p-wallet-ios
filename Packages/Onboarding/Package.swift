// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Onboarding",
    platforms: [
        .macOS(.v12),
        .iOS(.v14),
        .tvOS(.v13),
        .watchOS(.v6),
        
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Onboarding",
            targets: ["Onboarding"]),
    ],
    dependencies: [
        .package(path: "../AnalyticsManager"),
        .package(path: "../JSBridge"),
        .package(path: "../KeyAppKit"),
        .package(url: "https://github.com/p2p-org/solana-swift", branch: "main"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "1.6.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Onboarding",
            dependencies: [
                "JSBridge",
                .product(name: "SolanaSwift", package: "solana-swift"),
                .product(name: "CryptoSwift", package: "CryptoSwift"),
                "AnalyticsManager",
                .product(name: "KeyAppKitCore", package: "KeyAppKit"),
            ],
            resources: [
                .process("Resource/index.html"),
            ]
        ),
        .testTarget(name: "OnboardingTests", dependencies: ["Onboarding"]),
    ]
)
