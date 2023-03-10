//
//  File.swift
//
//
//  Created by Giang Long Tran on 09.03.2023.
//

import Cache
import Foundation
import SolanaPricesAPIs

/// This class service allow client to get exchange rate between token and fiat.
///
/// Each rate has 15 minutes lifetime. When the lifetime is expired, the new rate will be requested.
public class EthereumPriceService {
    /// Provider.
    internal let api: CoinGeckoPricesAPI

    /// Cache manager.
    internal let cache: LongTermCache<String, CurrentPrice>

    public init(api: CoinGeckoPricesAPI, lifetime: TimeInterval = 60 * 15) {
        self.api = api
        self.cache = LongTermCache(entryLifetime: lifetime, maximumEntryCount: 999)
    }

    public func getEthereumPrice(fiat: String) async throws -> Double {
        let response = try await api.getSimplePrice(ids: ["ethereum"], fiat: [fiat])
        guard
            let token = response["ethereum"],
            let price = token[fiat]
        else {
            throw Error.canNotExtractEthereumPrice
        }

        return price
    }

    /// Get prices for erc-20 tokens.
    public func getPrices(tokens: [EthereumToken], fiat: String) async throws -> [EthereumToken: Double?] {
        let contractAddresses = tokens.map { token -> String? in
            switch token.contractType {
            case let .erc20(contract: address):
                return address.hex(eip55: false)
            default:
                return nil
            }
        }
        .compactMap { $0 }

        let result = try await api.getSimpleTokenPrice(platform: "ethereum", contractAddresses: contractAddresses, fiat: ["usd"])

        return Dictionary(
            tokens.map { token in
                switch token.contractType {
                case let .erc20(contract: address):
                    return (token, result[address.hex(eip55: true)]?[fiat])
                default:
                    return (token, nil)
                }
            },
            uniquingKeysWith: { _, last in last }
        )
    }
}

public extension EthereumPriceService {
    enum Error: Swift.Error {
        case canNotExtractEthereumPrice
    }
}
