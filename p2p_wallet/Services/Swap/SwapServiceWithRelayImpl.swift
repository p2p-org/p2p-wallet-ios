//
// Created by Giang Long Tran on 01.02.2022.
//

import FeeRelayerSwift
import Foundation
import OrcaSwapSwift
import RxSwift

class SwapServiceWithRelayImpl: SwapServiceType {
    private let solanaClient: SolanaSDK
    private let accountStorage: SolanaSDKAccountStorage
    private let feeRelayApi: FeeRelayerAPIClientType
    private let orcaSwap: OrcaSwapType
    private var relayService: FeeRelayerRelayType?
    @Injected var notification: NotificationsServiceType

    init(
        solanaClient: SolanaSDK,
        accountStorage: SolanaSDKAccountStorage,
        feeRelay: FeeRelayerAPIClientType,
        orcaSwap: OrcaSwapType
    ) {
        self.solanaClient = solanaClient
        self.accountStorage = accountStorage
        feeRelayApi = feeRelay
        self.orcaSwap = orcaSwap
    }

    func load() -> Completable {
        do {
            relayService = try FeeRelayer.Relay(
                apiClient: feeRelayApi,
                solanaClient: solanaClient,
                accountStorage: accountStorage,
                orcaSwapClient: orcaSwap
            )

            return .zip(
                orcaSwap.load(),
                relayService!.load()
            )
        } catch {
            return .error(error)
        }
    }

    func getSwapInfo(from _: SolanaSDK.Token, to _: SolanaSDK.Token) -> Swap.SwapInfo {
        .init(payingTokenMode: .any)
    }

    func getPoolPair(
        from sourceMint: String,
        to destinationMint: String,
        amount _: UInt64,
        as _: Swap.InputMode
    ) -> Single<[Swap.PoolsPair]> {
        orcaSwap.getTradablePoolsPairs(fromMint: sourceMint, toMint: destinationMint)
            .map { result in result.map { $0.toPoolsPair() } }
    }

    func getFees(
        sourceAddress _: String,
        sourceMint: String,
        availableSourceMintAddresses _: [String],
        destinationAddress: String?,
        destinationToken: SolanaSDK.Token,
        bestPoolsPair: Swap.PoolsPair?,
        payingWallet: Wallet?,
        inputAmount: Double?,
        slippage: Double,
        lamportsPerSignature _: UInt64,
        minRentExempt _: UInt64
    ) -> Single<Swap.FeeInfo> {
        let bestPoolsPair = bestPoolsPair as? PoolsPair
        // Network fees
        let networkFeesRequest: Single<[PayingFee]>

        if let payingWallet = payingWallet {
            // Network fee for swapping via relay program
            networkFeesRequest = getNetworkFeesForSwappingViaRelayProgram(
                swapPools: bestPoolsPair?.orcaPoolPair,
                sourceMint: sourceMint,
                destinationAddress: destinationAddress,
                destinationToken: destinationToken,
                payingWallet: payingWallet
            )
        } else {
            networkFeesRequest = .just([])
        }

        return networkFeesRequest
            .map { [weak self] networkFees in
                guard let self = self else { throw SolanaSDK.Error.unknown }

                // Liquidity provider fee
                let liquidityProviderFees = try self.getLiquidityProviderFees(
                    poolsPair: bestPoolsPair?.orcaPoolPair,
                    destinationAddress: destinationAddress,
                    destinationToken: destinationToken,
                    inputAmount: inputAmount,
                    slippage: slippage
                )

                return Swap.FeeInfo(fees: networkFees + liquidityProviderFees)
            }
    }

    public func findPosibleDestinationMints(fromMint: String) throws -> [String] {
        try orcaSwap.findPosibleDestinationMints(fromMint: fromMint)
    }

    func calculateNetworkFeeInPayingToken(
        networkFee: SolanaSDK.FeeAmount,
        payingTokenMint: String
    ) -> Single<SolanaSDK.FeeAmount?> {
        if payingTokenMint == SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString {
            return .just(networkFee)
        }
        return relayService!.calculateFeeInPayingToken(feeInSOL: networkFee, payingFeeTokenMint: payingTokenMint)
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
    ) -> Single<[String]> {
        guard let poolsPair = (poolsPair as? PoolsPair)?.orcaPoolPair,
              let decimals = poolsPair.first?.getTokenADecimals()
        else { return .error(Swap.Error.incompatiblePoolsPair) }

        return swapViaRelayProgram(
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
        let orcaPoolPair: OrcaSwap.PoolsPair

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
        poolsPair: OrcaSwap.PoolsPair?,
        destinationAddress: String?,
        destinationToken: SolanaSDK.Token?,
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
        swapPools: OrcaSwap.PoolsPair?,
        sourceMint: String,
        destinationAddress: String?,
        destinationToken: SolanaSDK.Token,
        payingWallet: Wallet
    ) -> Single<[PayingFee]> {
        relayService!.calculateSwappingNetworkFees(
            swapPools: swapPools,
            sourceTokenMint: sourceMint,
            destinationTokenMint: destinationToken.address,
            destinationAddress: destinationAddress
        )
        .flatMap { [weak self] networkFee -> Single<SolanaSDK.FeeAmount> in
            guard let self = self else { throw SolanaSDK.Error.unknown }

            // when free transaction is not available and user is paying with sol, let him do this the normal way (don't use fee relayer)
            if self.isFreeTransactionNotAvailableAndUserIsPayingWithSOL(expectedTransactionFee: networkFee.transaction, payingTokenMint: payingWallet.mintAddress)
            {
                var networkFee = networkFee
                networkFee.transaction -= (self.relayService?.cache.lamportsPerSignature ?? 5000)
                return .just(networkFee)
            }

            // send via fee relayer
            return self.relayService!.calculateNeededTopUpAmount(expectedFee: networkFee, payingTokenMint: payingWallet.mintAddress)
        }
        .flatMap { [weak self] feeAmount -> Single<SolanaSDK.FeeAmount> in
            guard let self = self else { throw SolanaSDK.Error.unknown }
            if payingWallet.mintAddress == SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString {
                return .just(feeAmount)
            }
            return self.relayService!.calculateFeeInPayingToken(feeInSOL: feeAmount, payingFeeTokenMint: payingWallet.mintAddress)
                .map { $0 ?? .zero }
        }
        .map { [weak self] neededTopUpAmount in
            guard let self = self else { throw FeeRelayer.Error.unknown }

            let freeTransactionFeeLimit = self.relayService?.cache.freeTransactionFeeLimit

            var allFees = [PayingFee]()
            var isFree = false
            var info: PayingFee.Info?

            if neededTopUpAmount.transaction == 0 {
                isFree = true

                var numberOfFreeTransactionsLeft = 100
                var maxUsage = 100

                if let freeTransactionFeeLimit = freeTransactionFeeLimit {
                    numberOfFreeTransactionsLeft = freeTransactionFeeLimit.maxUsage - freeTransactionFeeLimit.currentUsage
                    maxUsage = freeTransactionFeeLimit.maxUsage
                }

                info = .init(
                    alertTitle: L10n.thereAreFreeTransactionsLeftForToday(numberOfFreeTransactionsLeft),
                    alertDescription: L10n.OnTheSolanaNetworkTheFirstTransactionsInADayArePaidByP2P.Org.subsequentTransactionsWillBeChargedBasedOnTheSolanaBlockchainGasFee(maxUsage),
                    payBy: L10n.PaidByP2p.org
                )
            }

            if sourceMint == SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString {
                allFees.append(
                    .init(
                        type: .depositWillBeReturned,
                        lamports: self.relayService?.cache.minimumTokenAccountBalance ?? 2_039_280,
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
                    toString: nil,
                    isFree: isFree,
                    info: info
                )
            )

            return allFees
        }
    }

    private func swapViaRelayProgram(
        sourceAddress: String,
        sourceTokenMint: String,
        destinationAddress: String?,
        destinationTokenMint: String,
        payingTokenAddress: String?,
        payingTokenMint: String?,
        poolsPair: OrcaSwap.PoolsPair,
        amount: UInt64,
        decimals: UInt8,
        slippage: Double
    ) -> Single<[String]> {
        guard let feeRelay = relayService else { return .error(SolanaSDK.Error.other("Fee relay is not ready")) }
        var payingFeeToken: FeeRelayer.Relay.TokenInfo?
        if let payingTokenAddress = payingTokenAddress, let payingTokenMint = payingTokenMint {
            payingFeeToken = FeeRelayer.Relay.TokenInfo(address: payingTokenAddress, mint: payingTokenMint)
        }
        // when free transaction is not available and user is paying with sol, let him do this the normal way (don't use fee relayer)
        if isFreeTransactionNotAvailableAndUserIsPayingWithSOL(payingTokenMint: payingTokenMint) {
            return orcaSwap.swap(
                fromWalletPubkey: sourceAddress,
                toWalletPubkey: destinationAddress,
                bestPoolsPair: poolsPair,
                amount: amount.convertToBalance(decimals: decimals),
                slippage: slippage,
                isSimulation: false
            ).map { response in [response.transactionId] }
        }
        return feeRelay.prepareSwapTransaction(
            sourceToken: FeeRelayer.Relay.TokenInfo(address: sourceAddress, mint: sourceTokenMint),
            destinationTokenMint: destinationTokenMint,
            destinationAddress: destinationAddress,
            payingFeeToken: payingFeeToken,
            swapPools: poolsPair,
            inputAmount: amount,
            slippage: slippage
        ).flatMap { [weak self] transactions in
            guard let feeRelay = self?.relayService else { throw SolanaSDK.Error.other("Fee relay is deallocated") }
            return feeRelay.topUpAndRelayTransactions(preparedTransactions: transactions, payingFeeToken: payingFeeToken)
        }
    }

    private func isFreeTransactionNotAvailableAndUserIsPayingWithSOL(
        expectedTransactionFee: UInt64? = nil,
        payingTokenMint: String?
    ) -> Bool {
        let expectedTransactionFee = expectedTransactionFee ?? (relayService?.cache.lamportsPerSignature ?? 5000) * 2
        return payingTokenMint == SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString &&
            relayService?.cache.freeTransactionFeeLimit?.isFreeTransactionFeeAvailable(transactionFee: expectedTransactionFee) == false
    }
}

private extension OrcaSwap.PoolsPair {
    func toPoolsPair() -> SwapServiceWithRelayImpl.PoolsPair { .init(orcaPoolPair: self) }
}
