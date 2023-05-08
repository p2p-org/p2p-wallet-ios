import Foundation
import SolanaSwift
import KeyAppKitCore

extension SolanaAPIClient {
    /// Method retrieves token wallets
    /// - Parameters:
    ///  - account: Public key of an account
    ///  - tokensRepository: Solana token repository,
    /// - Throws: TokenRepositoryError
    /// - Returns array of Wallet
    ///
    func getTokenWallets(
        account: String,
        tokensRepository: SolanaTokensRepository? = nil,
        commitment: Commitment? = nil
    ) async throws -> [SolanaAccount] {
        async let accounts = try await getTokenAccountsByOwner(
            pubkey: account,
            params: .init(
                mint: nil,
                programId: TokenProgram.id.base58EncodedString
            ),
            configs: .init(
                commitment: commitment,
                encoding: "base64"
            )
        )
        let tokensRepository = tokensRepository ?? TokensRepository(endpoint: endpoint)
        async let tokens = try await tokensRepository.getTokensList()
        var knownWallets = [SolanaAccount]()
        var unknownAccounts = [(String, AccountInfo)]()
        let (list, supportedTokens) = (try await accounts, try await tokens)
        
        for item in list {
            let pubkey = item.pubkey
            let accountInfo = item.account.data
            
            let mintAddress = accountInfo.mint.base58EncodedString
            // known token
            if let token = supportedTokens.first(where: { $0.address == mintAddress }) {
                knownWallets.append(
                    SolanaAccount(
                        pubkey: pubkey,
                        lamports: accountInfo.lamports,
                        token: token
                    )
                )
            } else {
                // unknown token
                unknownAccounts.append((item.pubkey, item.account.data))
            }
        }
        let mintDatas = try await getMultipleMintDatas(mintAddresses: unknownAccounts.map(\.1.mint.base58EncodedString))
        guard mintDatas.count == unknownAccounts.count else { throw SolanaError.unknown }
        let wallets: [SolanaAccount] = mintDatas.compactMap { address, mint in
            if let unknownAccount = unknownAccounts.first(where: { $0.1.mint.base58EncodedString == address }) {
                return SolanaAccount(
                    pubkey: unknownAccount.0,
                    lamports: unknownAccount.1.lamports,
                    supply: mint.supply,
                    token: .unsupported(
                        mint: unknownAccount.1.mint.base58EncodedString,
                        decimals: mint.decimals,
                        supply: mint.supply
                    )
                )
            } else {
                return nil
            }
        }
        return knownWallets + wallets
    }
}
