//
// Created by Giang Long Tran on 05.05.2022.
//

import Foundation
import SolanaSwift

extension TokenRepository {
    func safeGet(address: String?) async throws -> TokenMetadata {
        if let address {
            return try await get(address: address)
                ?? .unsupported(mint: address, decimals: 1, symbol: "", supply: nil)
        } else {
            return .unsupported(mint: "", decimals: 1, symbol: "", supply: nil)
        }
    }

    func safeGet(address: PublicKey?) async throws -> TokenMetadata {
        if let address {
            return try await safeGet(address: address.base58EncodedString)
        } else {
            return .unsupported(mint: "", decimals: 1, symbol: "", supply: nil)
        }
    }
}
