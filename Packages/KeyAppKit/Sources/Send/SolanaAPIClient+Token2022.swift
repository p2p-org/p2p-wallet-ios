import Foundation
import SolanaSwift

extension SolanaAPIClient {
    func getTokenAccountsByOwnerWithToken2022(
        pubkey: String,
        params: OwnerInfoParams?,
        configs: RequestConfiguration?
    ) async throws -> [TokenAccount<SPLTokenAccountState>]
    { // Temporarily convert all state into basic SPLTokenAccountState layout
        async let classicTokenAccounts = getTokenAccountsByOwner(
            pubkey: pubkey,
            params: params,
            configs: configs,
            decodingTo: SPLTokenAccountState.self
        )

        async let token2022Accounts = getTokenAccountsByOwner(
            pubkey: pubkey,
            params: params,
            configs: configs,
            decodingTo: SPLTokenAccountState.self
        )

        return try await classicTokenAccounts + token2022Accounts
    }
}
