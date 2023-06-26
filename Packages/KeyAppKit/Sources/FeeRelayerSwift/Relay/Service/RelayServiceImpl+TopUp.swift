import Foundation
import SolanaSwift
import OrcaSwapSwift

extension RelayServiceImpl {
    /// Check and top up (if needed)
    /// - Parameters:
    ///   - context: current context of Relay's service
    ///   - expectedFee: expected fee for a transaction
    ///   - payingFeeToken: token to pay fee
    /// - Returns: nil if top up is not needed, transactions' signatures if top up has been sent
    func topUpIfNeeded(
        expectedFee: FeeAmount,
        payingFeeToken: TokenAccount?
    ) async throws -> [String]? {
        // get current context
        guard let context = contextManager.currentContext else {
            throw RelayContextManagerError.invalidContext
        }
        
        // if paying fee token is solana, skip the top up
        // and transfer SOL directly to feePayer address
        if payingFeeToken?.mint == PublicKey.wrappedSOLMint {
            return nil
        }
        
        // calculate needed topUpAmount
        let topUpAmount = try await feeCalculator.calculateNeededTopUpAmount(
            context,
            expectedFee: expectedFee,
            payingTokenMint: payingFeeToken?.mint
        )
        
        // no need to top up if amount <= 0
        guard topUpAmount.total > 0 else {
            return nil
        }
        
        // top up
        let payingFeeToken = try payingFeeToken ?! FeeRelayerError.unknown
        
        let poolsPair = try await getPoolsPairForTopUp(
            topUpAmount: topUpAmount.total,
            payingFeeToken: payingFeeToken
        )
        
        return try await topUp(
            sourceToken: payingFeeToken,
            targetAmount: topUpAmount.total,
            topUpPools: poolsPair
        )
    }
    
    /// Get poolsPair for topUp
    /// - Parameters:
    ///   - context: current context of Relay's service
    ///   - topUpAmount: amount that needs to top up
    ///   - payingFeeToken: token to pay fee
    ///   - forceUsingTransitiveSwap: force using transitive swap (for testing purpose only)
    /// - Returns: PoolsPair for topUp
    func getPoolsPairForTopUp(
        topUpAmount: Lamports,
        payingFeeToken: TokenAccount,
        forceUsingTransitiveSwap: Bool = false // true for testing purpose only
    ) async throws -> PoolsPair {
        // form request
        let tradableTopUpPoolsPair = try await orcaSwap.getTradablePoolsPairs(
            fromMint: payingFeeToken.mint.base58EncodedString,
            toMint: PublicKey.wrappedSOLMint.base58EncodedString
        )
        // Get pools for topping up
        let topUpPools: PoolsPair
        // force using transitive swap (for testing only)
        if forceUsingTransitiveSwap {
            let pools = tradableTopUpPoolsPair.first(where: {$0.count == 2})!
            topUpPools = pools
        }
        // prefer direct swap to transitive swap
        else if let directSwapPools = tradableTopUpPoolsPair.first(where: {$0.count == 1}) {
            topUpPools = directSwapPools
        }
        // if direct swap is not available, use transitive swap
        else if let transitiveSwapPools = try orcaSwap.findBestPoolsPairForEstimatedAmount(topUpAmount, from: tradableTopUpPoolsPair) {
            topUpPools = transitiveSwapPools
        }
        // no swap is available
        else {
            throw FeeRelayerError.swapPoolsNotFound
        }
        // return needed amount and pools
        return topUpPools
    }
    
    /// Top up to fill relay account before relaying any transaction
    /// - Parameters:
    ///   - context: current context of Relay's service
    ///   - needsCreateUserRelayAddress: indicate if creating user relay address is required
    ///   - sourceToken: token to top up from
    ///   - targetAmount: amount that needs to be topped up
    ///   - topUpPools: pools used to swap to top up
    ///   - expectedFee: expected fee of the transaction that requires top up
    /// - Returns: transaction's signature
    func topUp(
        sourceToken: TokenAccount,
        targetAmount: UInt64,
        topUpPools: PoolsPair
    ) async throws -> [String] {
        // get current context
        guard let context = contextManager.currentContext else {
            throw RelayContextManagerError.invalidContext
        }
        
        let blockhash = try await solanaApiClient.getRecentBlockhash(commitment: nil)

        // STEP 3: prepare for topUp
        let topUpTransactionBuilder = TopUpTransactionBuilderImpl(
            solanaApiClient: solanaApiClient,
            orcaSwap: orcaSwap,
            account: account
        )
        let (swapData, preparedTransaction) = try await topUpTransactionBuilder.buildTopUpTransaction(
            context: context,
            sourceToken: sourceToken,
            topUpPools: topUpPools,
            targetAmount: targetAmount,
            blockhash: blockhash
        )
        
        // STEP 4: send transaction
        let signatures = preparedTransaction.transaction.signatures
        guard signatures.count >= 2 else { throw FeeRelayerError.invalidSignature }
        
        // the second signature is the owner's signature
        let ownerSignature = try signatures.getSignature(index: 1)
        
        // the third signature (optional) is the transferAuthority's signature
        let transferAuthoritySignature = try? signatures.getSignature(index: 2)
        
        let topUpSignatures = SwapTransactionSignatures(
            userAuthoritySignature: ownerSignature,
            transferAuthoritySignature: transferAuthoritySignature
        )
        let result = try await self.feeRelayerAPIClient.sendTransaction(
            .relayTopUpWithSwap(
                .init(
                    userSourceTokenAccount: sourceToken.address,
                    sourceTokenMint: sourceToken.mint,
                    userAuthority: account.publicKey,
                    topUpSwap: .init(swapData),
                    feeAmount: preparedTransaction.expectedFee.total,
                    signatures: topUpSignatures,
                    blockhash: blockhash,
                    deviceType: self.deviceType,
                    buildNumber: self.buildNumber,
                    environment: self.environment
                )
            )
        )
        return [result]
    }
}
