import Foundation
import SolanaSwift

/// Destination finder result
public enum DestinationAnalysatorResult: Equatable {
    case wsolAccount
    case splAccount(needsCreation: Bool)
}

/// Destination finding service
public protocol DestinationAnalysator {
    /// User may give SOL address or SPL token address as destination,
    /// so this method will check and give the correct destination
    /// that map user's address and mint address of the token.
    /// - Parameters:
    ///   - owner: account's owner
    ///   - mint: token mint
    /// - Returns:
    func analyseDestination(
        owner: PublicKey,
        mint: PublicKey
    ) async throws -> DestinationAnalysatorResult
}

public class DestinationAnalysatorImpl: DestinationAnalysator {
    private let solanaAPIClient: SolanaAPIClient

    public init(solanaAPIClient: SolanaAPIClient) {
        self.solanaAPIClient = solanaAPIClient
    }

    public func analyseDestination(
        owner: PublicKey,
        mint: PublicKey
    ) async throws -> DestinationAnalysatorResult {
        // Destination is wsol, wsol temporary account creation is needed
        if PublicKey.wrappedSOLMint == mint {
            return .wsolAccount
        }

        // Destination is SPL token
        else {
            // Try to get associated account
            let address = try await solanaAPIClient.getAssociatedSPLTokenAddress(for: owner, mint: mint)

            // Check destination address is exist.
            let info: BufferInfo<TokenAccountState>? = try? await solanaAPIClient
                .getAccountInfo(account: address.base58EncodedString)
            let needsCreateDestinationTokenAccount = !PublicKey.isSPLTokenProgram(info?.owner)

            return .splAccount(needsCreation: needsCreateDestinationTokenAccount)
        }
    }
}
