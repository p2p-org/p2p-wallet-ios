// swift-tools-version:5.7.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KeyAppKit",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v13),
        .watchOS(.v6),

    ],
    products: [
        .library(name: "Cache", targets: ["Cache"]),

        .library(
            name: "KeyAppKitLogger",
            targets: ["KeyAppKitLogger"]
        ),

        .library(
            name: "NameService",
            targets: ["NameService"]
        ),

        .library(
            name: "KeyAppNetworking",
            targets: ["KeyAppNetworking"]
        ),

        // Analytics manager for wallet
        .library(
            name: "AnalyticsManager",
            targets: ["AnalyticsManager"]
        ),

        // JSBridge
        .library(
            name: "JSBridge",
            targets: ["JSBridge"]
        ),

        // Countries
        .library(
            name: "CountriesAPI",
            targets: ["CountriesAPI"]
        ),

        // Tkey
        .library(
            name: "Onboarding",
            targets: ["Onboarding"]
        ),

        // Send
        .library(
            name: "Send",
            targets: ["Send"]
        ),

        // History
        .library(
            name: "History",
            targets: ["History"]
        ),

        // Sell
        .library(
            name: "Sell",
            targets: ["Sell"]
        ),

        // Moonpay
        .library(
            name: "Moonpay",
            targets: ["Moonpay"]
        ),

        // Wormhole
        .library(
            name: "Wormhole",
            targets: ["Wormhole"]
        ),

        // Library
        .library(
            name: "FeeRelayerSwift",
            targets: ["FeeRelayerSwift"]
        ),

        .library(
            name: "OrcaSwapSwift",
            targets: ["OrcaSwapSwift"]
        ),

        .library(
            name: "TokenService",
            targets: ["TokenService"]
        ),

        // KeyAppBusiness
        .library(
            name: "KeyAppBusiness",
            targets: ["KeyAppBusiness"]
        ),

        .library(
            name: "Jupiter",
            targets: ["Jupiter"]
        ),

        .library(
            name: "KeyAppStateMachine",
            targets: ["KeyAppStateMachine"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/p2p-org/solana-swift", branch: "feature/token-2022"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "1.6.0")),
        .package(url: "https://github.com/Boilertalk/Web3.swift.git", from: "0.6.0"),
        // .package(url: "https://github.com/trustwallet/wallet-core", branch: "master"),
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.3.0"),
        .package(url: "https://github.com/p2p-org/BigDecimal.git", branch: "main"),
        .package(url: "https://github.com/vapor/websocket-kit", from: "2.8.0"),
        .package(url: "https://github.com/amplitude/Amplitude-iOS.git", from: "8.15.0"),
        .package(url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework", from: "6.12.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.7.0"),
    ],
    targets: [
        .binaryTarget(
            name: "WalletCore",
            path: "Frameworks/WalletCore.xcframework.zip"
        ),

        .binaryTarget(
            name: "XCSwiftProtobuf",
            path: "Frameworks/SwiftProtobuf.xcframework.zip"
        ),

        // Cache
        .target(name: "Cache"),

        // KeyAppKitLogger
        .target(name: "KeyAppKitLogger"),

        // Name Service
        .target(
            name: "NameService",
            dependencies: [
                "KeyAppKitLogger",
                "KeyAppKitCore",
                .product(name: "SolanaSwift", package: "solana-swift"),
            ]
        ),
        .testTarget(
            name: "NameServiceIntegrationTests",
            dependencies: [
                "NameService",
                .product(name: "SolanaSwift", package: "solana-swift"),
            ],
            path: "Tests/IntegrationTests/NameServiceIntegrationTests"
        ),

        .target(name: "KeyAppNetworking"),
        .testTarget(
            name: "KeyAppNetworkingTests",
            dependencies: [
                "KeyAppNetworking",
            ],
            path: "Tests/UnitTests/KeyAppNetworkingTests"
        ),

        // AnalyticsManager
        .target(
            name: "AnalyticsManager",
            dependencies: [
                .product(name: "Amplitude", package: "Amplitude-iOS"),
                .product(name: "AppsFlyerLib", package: "AppsFlyerFramework"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
            ]
        ),
        .testTarget(
            name: "AnalyticsManagerUnitTests",
            dependencies: ["AnalyticsManager"],
            path: "Tests/UnitTests/AnalyticsManagerUnitTests"
        ),

        // JSBridge
        .target(
            name: "JSBridge"
        ),
        .testTarget(
            name: "JSBridgeTests",
            dependencies: ["JSBridge"],
            path: "Tests/UnitTests/JSBridgeTests"
        ),

        // Countries
        .target(
            name: "CountriesAPI",
            resources: [
                .process("Resources/countries.json"),
            ]
        ),
        .testTarget(
            name: "CountriesAPIUnitTests",
            dependencies: ["CountriesAPI"],
            path: "Tests/UnitTests/CountriesAPIUnitTests"
            //      resources: [.process("./Resource")]
        ),

        // TKey
        .target(
            name: "Onboarding",
            dependencies: [
                "JSBridge",
                .product(name: "SolanaSwift", package: "solana-swift"),
                .product(name: "CryptoSwift", package: "CryptoSwift"),
                "AnalyticsManager",
                "KeyAppKitCore",
            ],
            resources: [
                .process("Resource/index.html"),
            ]
        ),
        .testTarget(name: "OnboardingTests", dependencies: ["Onboarding"]),

        .target(
            name: "Send",
            dependencies: [
                .product(name: "SolanaSwift", package: "solana-swift"),
                "FeeRelayerSwift",
                "NameService",
                "History",
                "Wormhole",
                "KeyAppNetworking",
                "TokenService",
            ]
        ),

        .testTarget(
            name: "SendTest",
            dependencies: ["Send"],
            path: "Tests/UnitTests/SendTests"
        ),

        // History
        .target(
            name: "History",
            dependencies: [
                "Onboarding",
                .product(name: "SolanaSwift", package: "solana-swift"),
            ]
        ),

        // Sell
        .target(
            name: "Sell",
            dependencies: ["Moonpay", "KeyAppBusiness"]
        ),

        // Moonpay
        .target(
            name: "Moonpay",
            dependencies: []
        ),

        // Wormhole
        .target(
            name: "Wormhole",
            dependencies: [
                "KeyAppBusiness",
                .product(name: "Web3", package: "Web3.swift"),
                .product(name: "Web3ContractABI", package: "Web3.swift"),
                .product(name: "SolanaSwift", package: "solana-swift"),
                "FeeRelayerSwift",
            ]
        ),
        .testTarget(
            name: "WormholeTests",
            dependencies: ["Wormhole"],
            path: "Tests/UnitTests/WormholeTests"
        ),

        .target(
            name: "Jupiter",
            dependencies: [
                .product(name: "SolanaSwift", package: "solana-swift"),
            ]
        ),

        .target(
            name: "TokenService",
            dependencies: [
                "KeyAppKitCore",
                "Cache",
                .product(name: "SolanaSwift", package: "solana-swift"),
                .product(name: "Web3", package: "Web3.swift"),
            ]
        ),

        .target(
            name: "KeyAppBusiness",
            dependencies: [
                "KeyAppKitCore",
                "Cache",
                "WalletCore",
                .product(name: "SolanaSwift", package: "solana-swift"),
                .product(name: "Web3", package: "Web3.swift"),
                .product(name: "Web3ContractABI", package: "Web3.swift"),
                "TokenService",
            ]
        ),
        .testTarget(
            name: "KeyAppBusinessTests",
            dependencies: ["KeyAppBusiness"],
            path: "Tests/UnitTests/KeyAppBusinessTests"
        ),

        // Fee relayer
        .target(
            name: "FeeRelayerSwift",
            dependencies: [
                .product(name: "SolanaSwift", package: "solana-swift"),
                "OrcaSwapSwift",
            ]
        ),
        .testTarget(
            name: "FeeRelayerSwiftUnitTests",
            dependencies: ["FeeRelayerSwift"]
        ),

        // Orca swap
        .target(
            name: "OrcaSwapSwift",
            dependencies: [
                .product(name: "SolanaSwift", package: "solana-swift"),
            ]
        ),
        .testTarget(
            name: "OrcaSwapUnitTests",
            dependencies: ["OrcaSwapSwift"],
            resources: []
        ),

        .testTarget(
            name: "OrcaSwapIntegrationTests",
            dependencies: ["OrcaSwapSwift"]
        ),

        // Core
        .target(
            name: "KeyAppKitCore",
            dependencies: [
                "WalletCore",
                "XCSwiftProtobuf",
                .product(name: "SolanaSwift", package: "solana-swift"),
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "Web3", package: "Web3.swift"),
                .product(name: "Web3ContractABI", package: "Web3.swift"),
                .product(name: "BigDecimal", package: "BigDecimal"),
            ]
        ),

        .testTarget(
            name: "KeyAppKitCoreTests",
            dependencies: ["KeyAppKitCore"],
            path: "Tests/UnitTests/KeyAppKitCoreTests"
        ),

        // StateMachine
        .target(
            name: "KeyAppStateMachine"
        ),

        .testTarget(
            name: "KeyAppStateMachineTests",
            dependencies: ["KeyAppStateMachine"],
            path: "Tests/UnitTests/KeyAppStateMachineTests"
        ),
    ]
)
