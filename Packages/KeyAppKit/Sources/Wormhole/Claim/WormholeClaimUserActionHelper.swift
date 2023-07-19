//
//  File.swift
//
//
//  Created by Giang Long Tran on 17.03.2023.
//

import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Web3

enum WormholeClaimUserActionHelper {
    static func extractEthereumToken(
        tokenAmount: TokenAmount,
        tokenRepository: EthereumTokensRepository
    ) async throws -> EthereumToken? {
        switch tokenAmount.token {
        case let .ethereum(contract):
            if let contract {
                return try await tokenRepository.resolve(address: EthereumAddress(hex: contract, eip55: false))
            } else {
                return EthereumToken()
            }
        default:
            return nil
        }
    }
}
