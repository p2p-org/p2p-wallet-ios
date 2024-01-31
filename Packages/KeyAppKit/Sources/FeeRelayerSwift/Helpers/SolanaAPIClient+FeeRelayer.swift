import Foundation
import SolanaSwift

extension SolanaAPIClient {
    public func getRelayAccountStatus(_ address: String) async throws -> RelayAccountStatus {
        let account: BufferInfo<EmptyInfo>? = try await getAccountInfo(account: address)
        guard let account = account else { return .notYetCreated }
        return .created(balance: account.lamports)
    }

    /// Retrieves associated SPL Token address for ``address``.
    ///
    /// - Returns: The associated address.
    func getAssociatedSPLTokenAddress(for address: PublicKey, mint: PublicKey) async throws -> PublicKey {
        let account: BufferInfo<TokenAccountState>? = try? await getAccountInfo(account: address.base58EncodedString)

        // The account doesn't exists
        if account == nil {
            return try PublicKey.associatedTokenAddress(
                walletAddress: address,
                tokenMintAddress: mint,
                tokenProgramId: TokenProgram.id
            )
        }

        // The account is already token account
        if account?.data.mint == mint {
            return address
        }

        // The native account
        guard account?.owner != SystemProgram.id.base58EncodedString else {
            throw FeeRelayerError.wrongAddress
        }
        return try PublicKey.associatedTokenAddress(
            walletAddress: address,
            tokenMintAddress: mint,
            tokenProgramId: TokenProgram.id
        )
    }

    func isAccountExists(_ address: PublicKey) async throws -> Bool {
        let account: BufferInfo<EmptyInfo>? = try await getAccountInfo(account: address.base58EncodedString)
        return account != nil
    }
}
