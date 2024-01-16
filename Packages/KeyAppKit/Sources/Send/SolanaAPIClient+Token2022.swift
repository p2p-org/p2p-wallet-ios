import Foundation
import SolanaSwift

extension SolanaAPIClient {
    func getTokenAccountsByOwnerWithToken2022(
        pubkey: String,
        configs: RequestConfiguration?
    ) async throws -> [TokenAccount<SPLTokenAccountState>]
    { // Temporarily convert all state into basic SPLTokenAccountState layout
        async let classicTokenAccounts = getTokenAccountsByOwner(
            pubkey: pubkey,
            params: .init(
                mint: nil,
                programId: TokenProgram.id.base58EncodedString
            ),
            configs: configs,
            decodingTo: SPLTokenAccountState.self
        )

        async let token2022Accounts = getTokenAccountsByOwner(
            pubkey: pubkey,
            params: .init(
                mint: nil,
                programId: Token2022Program.id.base58EncodedString
            ),
            configs: configs,
            decodingTo: SPLTokenAccountState.self
        )

        return try await classicTokenAccounts + token2022Accounts
    }
}
