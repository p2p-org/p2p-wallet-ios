//
// Created by Giang Long Tran on 01.02.2022.
//

import FeeRelayerSwift
import Foundation
import OrcaSwapSwift
import Resolver
import RxSwift
import SolanaSwift

/// Wrapper around OrcaSwapSwift and FeeRelayerSwift
class SwapServiceWithRelayImpl: SwapServiceType {
    @Injected private var orcaSwap: OrcaSwapType
    @Injected private var relayService: RelayService
    @Injected private var relayContextManager: RelayContextManager
    @Injected private var swapFeeCalculator: SwapFeeRelayerCalculator
    @Injected private var solanaAPIClient: SolanaAPIClient
    @Injected private var accountStorage: SolanaAccountStorage
    
    var prefersDirectSwap: Bool {
        GlobalAppState.shared.preferDirectSwap
    }

    func reload() async throws {
        try await orcaSwap.load()
        try await relayContextManager.update()
    }

    func getTradablePoolsPairs(
        from sourceMint: String,
        to destinationMint: String
    ) async throws -> [PoolsPair] {
        try await orcaSwap.getTradablePoolsPairs(fromMint: sourceMint, toMint: destinationMint)
    }
    
    func findBestPoolsPairForInputAmount(_ inputAmount: UInt64, from poolsPairs: [OrcaSwapSwift.PoolsPair]) throws -> PoolsPair? {
        try orcaSwap.findBestPoolsPairForInputAmount(inputAmount, from: poolsPairs, prefersDirectSwap: prefersDirectSwap)
    }
    
    func findBestPoolsPairForEstimatedAmount(_ estimatedAmount: UInt64, from poolsPairs: [OrcaSwapSwift.PoolsPair]) throws -> PoolsPair? {
        try orcaSwap.findBestPoolsPairForEstimatedAmount(estimatedAmount, from: poolsPairs, prefersDirectSwap: prefersDirectSwap)
    }

    func getFees(
        sourceMint: String,
        destinationAddress: String?,
        destinationToken: Token,
        bestPoolsPair: PoolsPair?,
        payingWallet: Wallet?,
        inputAmount: Double?,
        slippage: Double
    ) async throws -> SwapFeeInfo {
        let bestPoolsPair = bestPoolsPair
        // Network fees
        let networkFees: [PayingFee]
        if let payingWallet = payingWallet {
            // Network fee for swapping via relay program
            networkFees = try await getNetworkFeesForSwappingViaRelayProgram(
                swapPools: bestPoolsPair,
                sourceMint: sourceMint,
                destinationAddress: destinationAddress,
                destinationToken: destinationToken,
                payingWallet: payingWallet
            )
        } else {
            networkFees = []
        }

        // Liquidity provider fee
        let liquidityProviderFees = try getLiquidityProviderFees(
            poolsPair: bestPoolsPair,
            destinationAddress: destinationAddress,
            destinationToken: destinationToken,
            inputAmount: inputAmount,
            slippage: slippage
        )

        return SwapFeeInfo(fees: networkFees + liquidityProviderFees)
    }

    func findPosibleDestinationMints(fromMint: String) throws -> [String] {
        try orcaSwap.findPosibleDestinationMints(fromMint: fromMint)
    }

    func calculateNetworkFeeInPayingToken(
        networkFee: FeeAmount,
        payingTokenMint: String
    ) async throws -> FeeAmount? {
        if payingTokenMint == PublicKey.wrappedSOLMint.base58EncodedString { return networkFee }
        return try await relayService.feeCalculator.calculateFeeInPayingToken(
            orcaSwap: orcaSwap,
            feeInSOL: networkFee,
            payingFeeTokenMint: try PublicKey(string: payingTokenMint)
        )
    }

    func swap(
        sourceAddress: String,
        sourceTokenMint: String,
        destinationAddress: String?,
        destinationTokenMint: String,
        payingTokenAddress: String?,
        payingTokenMint: String?,
        poolsPair: PoolsPair,
        amount: UInt64,
        slippage: Double
    ) async throws -> [String] {
        guard let decimals = poolsPair.first?.getTokenADecimals()
        else { throw SwapError.incompatiblePoolsPair }

        return try await swapViaRelayProgram(
            sourceAddress: sourceAddress,
            sourceTokenMint: sourceTokenMint,
            destinationAddress: destinationAddress,
            destinationTokenMint: destinationTokenMint,
            payingTokenAddress: payingTokenAddress,
            payingTokenMint: payingTokenMint,
            poolsPair: poolsPair,
            amount: amount,
            decimals: decimals,
            slippage: slippage
        )
    }

    // MARK: - Helpers

    private func getLiquidityProviderFees(
        poolsPair: PoolsPair?,
        destinationAddress: String?,
        destinationToken: Token?,
        inputAmount: Double?,
        slippage: Double
    ) throws -> [PayingFee] {
        var allFees = [PayingFee]()

        let liquidityProviderFees = try orcaSwap.getLiquidityProviderFee(
            bestPoolsPair: poolsPair,
            inputAmount: inputAmount,
            slippage: slippage
        )

        if let poolsPair = poolsPair, destinationAddress != nil, let destinationToken = destinationToken {
            if liquidityProviderFees.count == 1 {
                allFees.append(
                    .init(
                        type: .liquidityProviderFee,
                        lamports: liquidityProviderFees.first!,
                        token: destinationToken
                    )
                )
            } else if liquidityProviderFees.count == 2 {
                let intermediaryTokenName = poolsPair[0].tokenBName
                if let decimals = poolsPair[0].getTokenBDecimals() {
                    allFees.append(
                        .init(
                            type: .liquidityProviderFee,
                            lamports: liquidityProviderFees.first!,
                            token: .unsupported(mint: nil, decimals: decimals, symbol: intermediaryTokenName)
                        )
                    )
                }

                allFees.append(
                    .init(
                        type: .liquidityProviderFee,
                        lamports: liquidityProviderFees.last!,
                        token: destinationToken
                    )
                )
            }
        }

        return allFees
    }

    private func getNetworkFeesForSwappingViaRelayProgram(
        swapPools: PoolsPair?,
        sourceMint: String,
        destinationAddress: String?,
        destinationToken: Token,
        payingWallet: Wallet
    ) async throws -> [PayingFee] {
        let context = try await relayContextManager.getCurrentContextOrUpdate()
        
        let sourceMint = try PublicKey(string: sourceMint)
        let destinationTokenMint = try PublicKey(string: destinationToken.address)
        let destinationAddress = try? PublicKey(string: destinationAddress)

        var networkFee = try await swapFeeCalculator.calculateSwappingNetworkFees(
            lamportsPerSignature: context.lamportsPerSignature,
            minimumTokenAccountBalance: context.minimumTokenAccountBalance,
            swapPoolsCount: swapPools?.count ?? 0,
            sourceTokenMint: sourceMint,
            destinationTokenMint: destinationTokenMint,
            destinationAddress: destinationAddress
        )

        // when free transaction is not available and user is paying with sol, let him do this the normal way (don't use fee relayer)
        if isSwappingNatively(
            context,
            expectedTransactionFee: networkFee.transaction,
            payingTokenMint: payingWallet.mintAddress
        ) {
            networkFee.transaction -= context.lamportsPerSignature
        } else {
            // send via fee relayer
            networkFee = try await relayService.feeCalculator.calculateNeededTopUpAmount(
                context,
                expectedFee: networkFee,
                payingTokenMint: try PublicKey(string: payingWallet.mintAddress)
            )
        }

        let neededTopUpAmount: FeeAmount
        if payingWallet.mintAddress == PublicKey.wrappedSOLMint.base58EncodedString {
            neededTopUpAmount = networkFee
        } else if networkFee.total > 0 {
            neededTopUpAmount = try await relayService.feeCalculator.calculateFeeInPayingToken(
                orcaSwap: orcaSwap,
                feeInSOL: networkFee,
                payingFeeTokenMint: try PublicKey(string: payingWallet.mintAddress)
            ) ?? .zero
        } else {
            neededTopUpAmount = .zero
        }

        let freeTransactionFeeLimit = context.usageStatus

        var allFees = [PayingFee]()
        var isFree = false
        var info: PayingFee.Info?

        if neededTopUpAmount.transaction == 0 {
            isFree = true

            let numberOfFreeTransactionsLeft = freeTransactionFeeLimit.maxUsage - freeTransactionFeeLimit
                .currentUsage
            let maxUsage = freeTransactionFeeLimit.maxUsage

            info = .init(
                alertTitle: L10n.thereAreFreeTransactionsLeftForToday(numberOfFreeTransactionsLeft),
                alertDescription: L10n.OnTheSolanaNetworkTheFirstTransactionsInADayArePaidByKeyApp.subsequentTransactionsWillBeChargedBasedOnTheSolanaBlockchainGasFee(maxUsage),
                payBy: L10n.paidByKeyApp
            )
        }

        if isSwappingNatively(
            context,
            payingTokenMint: PublicKey.wrappedSOLMint.base58EncodedString
        ) {
            allFees.append(
                .init(
                    type: .depositWillBeReturned,
                    lamports: context.minimumTokenAccountBalance,
                    token: .nativeSolana
                )
            )
        }

        if neededTopUpAmount.accountBalances > 0 {
            allFees.append(
                .init(
                    type: .accountCreationFee(token: destinationToken.symbol),
                    lamports: neededTopUpAmount.accountBalances,
                    token: payingWallet.token
                )
            )
        }

        allFees.append(
            .init(
                type: .transactionFee,
                lamports: neededTopUpAmount.transaction,
                token: payingWallet.token,
                isFree: isFree,
                info: info
            )
        )

        return allFees
    }

    private func swapViaRelayProgram(
        sourceAddress: String,
        sourceTokenMint: String,
        destinationAddress: String?,
        destinationTokenMint: String,
        payingTokenAddress: String?,
        payingTokenMint: String?,
        poolsPair: PoolsPair,
        amount: UInt64,
        decimals: UInt8,
        slippage: Double
    ) async throws -> [String] {
        guard let account = accountStorage.account else {
            throw SolanaError.unauthorized
        }
        
        // update and get current context
        try await relayContextManager.update()
        let context = try await relayContextManager.getCurrentContextOrUpdate()

        // get paying fee token
        var payingFeeToken: FeeRelayerSwift.TokenAccount?
        if let payingTokenAddress = payingTokenAddress, let payingTokenMint = payingTokenMint {
            payingFeeToken = FeeRelayerSwift.TokenAccount(
                address: try PublicKey(string: payingTokenAddress),
                mint: try PublicKey(string: payingTokenMint)
            )
        }

        // CASE 1: FeeRelayer is not needed
        if isSwappingNatively(context, payingTokenMint: payingTokenMint) {
            let id = try await orcaSwap.swap(
                fromWalletPubkey: sourceAddress,
                toWalletPubkey: destinationAddress,
                bestPoolsPair: poolsPair,
                amount: amount.convertToBalance(decimals: decimals),
                slippage: slippage,
                isSimulation: false
            )
            return [id.transactionId]
        }
        
        // CASE 2: FeeRelayer involved
        let sourceAddress = try PublicKey(string: sourceAddress)
        let sourceTokenMint = try PublicKey(string: sourceTokenMint)
        let destinationTokenMint = try PublicKey(string: destinationTokenMint)
        let destinationAddress = try? PublicKey(string: destinationAddress)

        // Build transaction
        
        let latestBlockhash = try await solanaAPIClient.getRecentBlockhash(commitment: nil)
        
        let builder = SwapTransactionBuilderImpl(
            network: solanaAPIClient.endpoint.network,
            transitTokenAccountManager: TransitTokenAccountManagerImpl(
                owner: account.publicKey,
                solanaAPIClient: solanaAPIClient,
                orcaSwap: orcaSwap
            ),
            destinationAnalysator: DestinationAnalysatorImpl(solanaAPIClient: solanaAPIClient),
            feePayerAddress: context.feePayerAddress,
            minimumTokenAccountBalance: context.minimumTokenAccountBalance,
            lamportsPerSignature: context.lamportsPerSignature
        )
    
        let result = try await builder.buildSwapTransaction(
            userAccount: account,
            pools: poolsPair,
            inputAmount: amount,
            slippage: slippage,
            sourceTokenAccount: .init(address: sourceAddress, mint: sourceTokenMint),
            destinationTokenMint: destinationTokenMint,
            destinationTokenAddress: destinationAddress,
            blockhash: latestBlockhash
        )

        return try await relayService.topUpAndRelayTransaction(
            result.transactions,
            fee: payingFeeToken,
            config: .init(
                additionalPaybackFee: result.additionalPaybackFee,
                operationType: .swap,
                currency: sourceTokenMint.base58EncodedString
            )
        )
    }

    /// when free transaction is not available and user is paying with sol, let him do this the normal way (don't use fee relayer)
    private func isSwappingNatively(
        _ context: RelayContext,
        expectedTransactionFee: UInt64? = nil,
        payingTokenMint: String?
    ) -> Bool {
        let expectedTransactionFee = expectedTransactionFee ?? context.lamportsPerSignature * 2
        return payingTokenMint == PublicKey.wrappedSOLMint.base58EncodedString &&
            context.usageStatus.isFreeTransactionFeeAvailable(transactionFee: expectedTransactionFee) == false
    }
}
