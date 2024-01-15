import Foundation
import OrcaSwapSwift
import SolanaSwift

public protocol TransitTokenAccountManager {
    func getTransitToken(pools: PoolsPair) throws -> TokenAccount?
    func checkIfNeedsCreateTransitTokenAccount(transitToken: TokenAccount?) async throws -> Bool?
}

public class TransitTokenAccountManagerImpl: TransitTokenAccountManager {
    private let owner: PublicKey
    private let solanaAPIClient: SolanaAPIClient
    private let orcaSwap: OrcaSwapType

    public init(owner: PublicKey, solanaAPIClient: SolanaAPIClient, orcaSwap: OrcaSwapType) {
        self.owner = owner
        self.solanaAPIClient = solanaAPIClient
        self.orcaSwap = orcaSwap
    }

    public func getTransitToken(pools: PoolsPair) throws -> TokenAccount? {
        guard let transitTokenMintPubkey = try getTransitTokenMintPubkey(pools: pools) else { return nil }

        let transitTokenAccountAddress = try RelayProgram.getTransitTokenAccountAddress(
            user: owner,
            transitTokenMint: transitTokenMintPubkey,
            network: solanaAPIClient.endpoint.network
        )

        return TokenAccount(
            address: transitTokenAccountAddress,
            mint: transitTokenMintPubkey,
            minimumTokenAccountBalance: getTransitTokenMintRentExemption(pools: pools) ?? 2_039_280
        )
    }

    func getTransitTokenMintPubkey(pools: PoolsPair) throws -> PublicKey? {
        guard pools.count == 2 else { return nil }
        let interTokenName = pools[0].tokenBName
        return try PublicKey(string: orcaSwap.getMint(tokenName: interTokenName))
    }

    func getTransitTokenMintRentExemption(pools: PoolsPair) -> UInt64? {
        guard pools.count == 2 else { return nil }
        return pools[0].tokenBMinimumBalanceForRentExemption
    }

    public func checkIfNeedsCreateTransitTokenAccount(transitToken: TokenAccount?) async throws -> Bool? {
        guard let transitToken = transitToken else { return nil }

        guard let account: BufferInfo<SPLTokenAccountState> = try await solanaAPIClient
            .getAccountInfo(account: transitToken.address.base58EncodedString)
        else {
            return true
        }

        return account.data.mint != transitToken.mint
    }
}
