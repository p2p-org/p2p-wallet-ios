//
// Created by Giang Long Tran on 01.02.2022.
//

import FeeRelayerSwift
import Foundation
import OrcaSwapSwift
import Resolver
import RxSwift
import SolanaSwift

class SwapServiceWithRelayImpl: SwapServiceType {
    @Injected private var orcaSwap: OrcaSwapType
    @Injected private var relayService: FeeRelayer
    @Injected private var swapRelayService: SwapFeeRelayer
    @Injected private var feeRelayerContextManager: FeeRelayerContextManager

    func load() async throws {
        try await orcaSwap.load()
        try await feeRelayerContextManager.update()
    }

    func getPoolPair(
        from sourceMint: String,
        to destinationMint: String
    ) async throws -> [Swap.PoolsPair] {
        let poolPairs = try await orcaSwap.getTradablePoolsPairs(fromMint: sourceMint, toMint: destinationMint)
        return poolPairs.map { $0.toPoolsPair() }
    }

    func getFees(
        sourceMint: String,
        destinationAddress: String?,
        destinationToken: Token,
        bestPoolsPair: Swap.PoolsPair?,
        payingWallet: Wallet?,
        inputAmount: Double?,
        slippage: Double
    ) async throws -> Swap.FeeInfo {
        let bestPoolsPair = bestPoolsPair as? PoolsPair
        // Network fees
        let networkFees: [PayingFee]
        if let payingWallet = payingWallet {
            // Network fee for swapping via relay program
            networkFees = try await getNetworkFeesForSwappingViaRelayProgram(
                swapPools: bestPoolsPair?.orcaPoolPair,
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
            poolsPair: bestPoolsPair?.orcaPoolPair,
            destinationAddress: destinationAddress,
            destinationToken: destinationToken,
            inputAmount: inputAmount,
            slippage: slippage
        )

        return Swap.FeeInfo(fees: networkFees + liquidityProviderFees)
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
        poolsPair: Swap.PoolsPair,
        amount: UInt64,
        slippage: Double
    ) async throws -> [String] {
        guard let poolsPair = (poolsPair as? PoolsPair)?.orcaPoolPair,
              let decimals = poolsPair.first?.getTokenADecimals()
        else { throw Swap.Error.incompatiblePoolsPair }

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

    struct PoolsPair: Swap.PoolsPair {
        let orcaPoolPair: OrcaSwapSwift.PoolsPair

        func getMinimumAmountOut(inputAmount: UInt64, slippage: Double) -> UInt64? {
            orcaPoolPair.getMinimumAmountOut(inputAmount: inputAmount, slippage: slippage)
        }

        func getInputAmount(fromEstimatedAmount estimatedAmount: UInt64) -> UInt64? {
            orcaPoolPair.getInputAmount(fromEstimatedAmount: estimatedAmount)
        }

        func getOutputAmount(fromInputAmount inputAmount: UInt64) -> UInt64? {
            orcaPoolPair.getOutputAmount(fromInputAmount: inputAmount)
        }
    }

    // MARK: - Helpers

    private func getLiquidityProviderFees(
        poolsPair: OrcaSwapSwift.PoolsPair?,
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
        swapPools: OrcaSwapSwift.PoolsPair?,
        sourceMint: String,
        destinationAddress: String?,
        destinationToken: Token,
        payingWallet: Wallet
    ) async throws -> [PayingFee] {
        let context = try await feeRelayerContextManager.getCurrentContext()

        var networkFee = try await swapRelayService.calculator.calculateSwappingNetworkFees(
            context,
            swapPools: swapPools,
            sourceTokenMint: try PublicKey(string: sourceMint),
            destinationTokenMint: try PublicKey(string: destinationToken.address),
            destinationAddress: try? PublicKey(string: destinationAddress)
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
        } else {
            // TODO: Zero?
            neededTopUpAmount = try await relayService.feeCalculator.calculateFeeInPayingToken(
                orcaSwap: orcaSwap,
                feeInSOL: networkFee,
                payingFeeTokenMint: try PublicKey(string: payingWallet.mintAddress)
            ) ?? .zero
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
                alertDescription: L10n.OnTheSolanaNetworkTheFirstTransactionsInADayArePaidByP2P.Org
                    .subsequentTransactionsWillBeChargedBasedOnTheSolanaBlockchainGasFee(maxUsage),
                payBy: L10n.PaidByP2p.org
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
        poolsPair: OrcaSwapSwift.PoolsPair,
        amount: UInt64,
        decimals: UInt8,
        slippage: Double
    ) async throws -> [String] {
        let context = try await feeRelayerContextManager.getCurrentContext()

        var payingFeeToken: FeeRelayerSwift.TokenAccount?
        if let payingTokenAddress = payingTokenAddress, let payingTokenMint = payingTokenMint {
            payingFeeToken = FeeRelayerSwift.TokenAccount(
                address: try PublicKey(string: payingTokenAddress),
                mint: try PublicKey(string: payingTokenMint)
            )
        }

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

        let preparedTransactions = try await swapRelayService.prepareSwapTransaction(
            context,
            sourceToken: FeeRelayerSwift.TokenAccount(
                address: try PublicKey(string: sourceAddress),
                mint: try PublicKey(string: sourceTokenMint)
            ),
            destinationTokenMint: try PublicKey(string: destinationTokenMint),
            destinationAddress: try? PublicKey(string: destinationAddress),
            fee: payingFeeToken,
            swapPools: poolsPair,
            inputAmount: amount,
            slippage: slippage
        )

        return try await relayService.topUpAndRelayTransaction(
            context,
            preparedTransactions.transactions,
            fee: payingFeeToken,
            config: .init(
                additionalPaybackFee: preparedTransactions.additionalPaybackFee,
                operationType: .swap,
                currency: sourceTokenMint
            )
        )
    }

    /// when free transaction is not available and user is paying with sol, let him do this the normal way (don't use fee relayer)
    private func isSwappingNatively(
        _ context: FeeRelayerContext,
        expectedTransactionFee: UInt64? = nil,
        payingTokenMint: String?
    ) -> Bool {
        let expectedTransactionFee = expectedTransactionFee ?? context.lamportsPerSignature * 2
        return payingTokenMint == PublicKey.wrappedSOLMint.base58EncodedString &&
            context.usageStatus.isFreeTransactionFeeAvailable(transactionFee: expectedTransactionFee) == false
    }
}

private extension PoolsPair {
    func toPoolsPair() -> SwapServiceWithRelayImpl.PoolsPair { .init(orcaPoolPair: self) }
}
