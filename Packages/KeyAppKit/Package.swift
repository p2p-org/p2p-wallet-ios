// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KeyAppKit",
    platforms: [
        .macOS(.v12),
        .iOS(.v14),
        .tvOS(.v13),
        .watchOS(.v6),

    ],
    products: [
        .library(name: "KeyAppKitCore", targets: ["KeyAppKitCore"]),
        .library(name: "Cache", targets: ["Cache"]),

        .library(
            name: "KeyAppKitLogger",
            targets: ["KeyAppKitLogger"]
        ),
        .library(
            name: "TransactionParser",
            targets: ["TransactionParser"]
        ),

        .library(
            name: "NameService",
            targets: ["NameService"]
        ),

        // Price service for wallet
        .library(
            name: "SolanaPricesAPIs",
            targets: ["SolanaPricesAPIs"]
        ),

        // Countries
        .library(
            name: "CountriesAPI",
            targets: ["CountriesAPI"]
        ),

        // Solend
        .library(
            name: "Solend",
            targets: ["Solend"]
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

        // KeyAppBusiness
        .library(
            name: "KeyAppBusiness",
            targets: ["KeyAppBusiness"]
        ),

        .library(
            name: "Jupiter",
            targets: ["Jupiter"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/p2p-org/solana-swift", branch: "main"),
        .package(url: "https://github.com/p2p-org/FeeRelayerSwift", branch: "feature/simple-topup-and-sign"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "1.6.0")),
        .package(url: "https://github.com/Boilertalk/Web3.swift.git", from: "0.6.0"),
        .package(url: "https://github.com/trustwallet/wallet-core", branch: "master"),
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.3.0"),
        .package(url: "https://github.com/p2p-org/BigDecimal.git", branch: "main"),
        .package(url: "https://github.com/bigearsenal/LoggerSwift.git", branch: "master")
    ],
    targets: [
        // Cache
        .target(name: "Cache"),

        // KeyAppKitLogger
        .target(name: "KeyAppKitLogger"),

        // Transaction Parser
        .target(
            name: "TransactionParser",
            dependencies: [
                "Cache",
                .product(name: "SolanaSwift", package: "solana-swift"),
            ]
        ),
        .testTarget(
            name: "TransactionParserUnitTests",
            dependencies: ["TransactionParser"],
            path: "Tests/UnitTests/TransactionParserUnitTests",
            resources: [.process("./Resource")]
        ),

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

        // PricesService
        .target(
            name: "SolanaPricesAPIs",
            dependencies: ["Cache", .product(name: "SolanaSwift", package: "solana-swift")]
        ),
        .testTarget(
            name: "SolanaPricesAPIsUnitTests",
            dependencies: ["SolanaPricesAPIs"],
            path: "Tests/UnitTests/SolanaPricesAPIsUnitTests"
            //      resources: [.process("./Resource")]
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

        // Solend
        .target(
            name: "Solend",
            dependencies: [
                "P2PSwift",
                .product(name: "FeeRelayerSwift", package: "FeeRelayerSwift"),
            ]
        ),
        .testTarget(
            name: "SolendUnitTests",
            dependencies: ["Solend"],
            path: "Tests/UnitTests/SolendUnitTests"
        ),

        // MARK: - P2P SDK

        .target(name: "P2PSwift"),

        .testTarget(
            name: "P2PTestsIntegrationTests",
            dependencies: ["P2PSwift"],
            path: "Tests/IntegrationTests/P2PTestsIntegrationTests"
        ),

        // TODO: Future migration
        // .binaryTarget(
        //     name: "p2p",
        //     path: "Frameworks/p2p.xcframework"
        // ),

        // Sell
        .target(
            name: "Sell",
            dependencies: ["Moonpay"]
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
                .product(name: "WalletCore", package: "wallet-core"),
                .product(name: "SwiftProtobuf", package: "wallet-core"),
                .product(name: "FeeRelayerSwift", package: "FeeRelayerSwift"),
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
            name: "KeyAppBusiness",
            dependencies: [
                "KeyAppKitCore",
                "Cache",
                "SolanaPricesAPIs",
                .product(name: "SolanaSwift", package: "solana-swift"),
                .product(name: "Web3", package: "Web3.swift"),
                .product(name: "Web3ContractABI", package: "Web3.swift"),
                .product(name: "WalletCore", package: "wallet-core"),
                .product(name: "SwiftProtobuf", package: "wallet-core"),
            ]
        ),
        .testTarget(
            name: "KeyAppBusinessTests",
            dependencies: ["KeyAppBusiness"],
            path: "Tests/UnitTests/KeyAppBusinessTests"
        ),

        // Core
        .target(
            name: "KeyAppKitCore",
            dependencies: [
                .product(name: "SolanaSwift", package: "solana-swift"),
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "Web3", package: "Web3.swift"),
                .product(name: "Web3ContractABI", package: "Web3.swift"),
                .product(name: "WalletCore", package: "wallet-core"),
                .product(name: "BigDecimal", package: "BigDecimal"),
                .product(name: "LoggerSwift", package: "LoggerSwift")
            ]
        ),

        .testTarget(
            name: "KeyAppKitCoreTests",
            dependencies: ["KeyAppKitCore"],
            path: "Tests/UnitTests/KeyAppKitCoreTests"
        ),
    ]
)

#if swift(>=5.6)
    // For generating docs purpose
    package.dependencies.append(.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"))
#endif
