// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let config = try? newJSONDecoder().decode(Config.self, from: jsonData)

import Foundation

// MARK: - Config

public struct SolendConfig: Codable, Equatable {
    public let programID: String
    public let assets: [SolendConfigAsset]
    // public let markets: [SolendMarket]
    // public let oracles: SolendOracles
}

// MARK: - ConfigAsset

public struct SolendConfigAsset: Codable, Hashable, Equatable {
    public let name, symbol: String
    public let decimals: Int
    public let mintAddress: String
    public let logo: String?

    public init(name: String, symbol: String, decimals: Int, mintAddress: String, logo: String?) {
        self.name = name
        self.symbol = symbol
        self.decimals = decimals
        self.mintAddress = mintAddress
        self.logo = logo
    }

    public func copy(name: String? = nil, logo: String? = nil) -> Self {
        return .init(
            name: name ?? self.name,
            symbol: symbol,
            decimals: decimals,
            mintAddress: mintAddress,
            logo: logo ?? self.logo
        )
    }
}

// MARK: - Market

public struct SolendMarket: Codable, Equatable {
    let name: String
    let isPrimary: Bool
    let marketDescription: String?
    let creator: String
    let owner: String
    let address, authorityAddress: String
    let reserves: [SolendReserve]

    enum CodingKeys: String, CodingKey {
        case name, isPrimary
        case marketDescription = "description"
        case creator, owner, address, authorityAddress, reserves
    }
}

// MARK: - Reserve

public struct SolendReserve: Codable, Equatable {
    let asset, address, collateralMintAddress, collateralSupplyAddress: String
    let liquidityAddress, liquidityFeeReceiverAddress: String
    let userBorrowCap, userSupplyCap: SolendUserCap?
}

public enum SolendUserCap: Codable, Equatable {
    case integer(Int)
    case string(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Int.self) {
            self = .integer(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        throw DecodingError.typeMismatch(
            SolendUserCap.self,
            DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for UserCap")
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .integer(x):
            try container.encode(x)
        case let .string(x):
            try container.encode(x)
        }
    }
}

// MARK: - Oracles

public struct SolendOracles: Codable, Equatable {
    let pythProgramID, switchboardProgramID: String
    let assets: [SolendOraclesAsset]
}

// MARK: - OraclesAsset

public struct SolendOraclesAsset: Codable, Equatable {
    let asset, priceAddress, switchboardFeedAddress: String
}
