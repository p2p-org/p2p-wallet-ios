import Foundation
import SolanaSwift

extension SolanaAPIClient {
    func getTokenAccountsByOwnerWithToken2022(
        pubkey: String,
        configs: RequestConfiguration?
    ) async throws -> [TokenAccount<TokenAccountState>]
    { // Temporarily convert all state into basic TokenAccountState layout
        async let classicTokenAccounts = getTokenAccountsByOwner(
            pubkey: pubkey,
            params: .init(
                mint: nil,
                programId: TokenProgram.id.base58EncodedString
            ),
            configs: configs,
            decodingTo: TokenAccountState.self
        )

        async let token2022Accounts = getTokenAccountsByOwner(
            pubkey: pubkey,
            params: .init(
                mint: nil,
                programId: Token2022Program.id.base58EncodedString
            ),
            configs: configs,
            decodingTo: TokenAccountState.self
        )

        return try await classicTokenAccounts + token2022Accounts
    }
}
