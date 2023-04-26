//
//  File.swift
//
//
//  Created by Giang Long Tran on 09.03.2023.
//

import Cache
import Foundation
import KeyAppKitCore
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
        cache = LongTermCache(entryLifetime: lifetime, maximumEntryCount: 999)
    }

    public func getEthereumPrice(fiat: String) async throws -> TokenPrice {
        let response = try await api.getSimplePrice(ids: ["ethereum"], fiat: [fiat])
        guard
            let token = response["ethereum"],
            let price = token[fiat]
        else {
            throw Error.canNotExtractEthereumPrice
        }

        return .init(currencyCode: fiat.uppercased(), value: price, token: EthereumToken())
    }

    /// Get prices for erc-20 tokens.
    public func getPrices(tokens: [EthereumToken], fiat: String) async throws -> [EthereumToken: TokenPrice] {
        let nativeETHOverride = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"

        let contractAddresses = tokens.map { token -> String? in
            switch token.contractType {
            case let .erc20(contract: address):
                return address.hex(eip55: false)
            default:
                return nativeETHOverride
            }
        }
        .compactMap { $0 }

        guard !contractAddresses.isEmpty else { return [:] }

        let result = try await api.getSimpleTokenPrice(
            platform: "ethereum",
            contractAddresses: contractAddresses,
            fiat: ["usd"]
        )

        return Dictionary(
            tokens.map { token in
                switch token.contractType {
                case let .erc20(contract: address):
                    let value = result[address.hex(eip55: false)]?[fiat]
                    return (token, .init(currencyCode: fiat.uppercased(), value: value, token: token))
                case .native:
                    let value = result[nativeETHOverride]?[fiat]
                    return (token, .init(currencyCode: fiat.uppercased(), value: value, token: token))
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
