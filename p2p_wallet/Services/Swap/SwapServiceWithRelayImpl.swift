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
        self.feeRelayApi = feeRelay
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

    func getSwapInfo(from sourceToken: SolanaSDK.Token, to destinationToken: SolanaSDK.Token) -> Swap.SwapInfo {
        // Determine a mode for paying fee
        var payingTokenMode: Swap.PayingTokenMode = .any
        if sourceToken.isNativeSOL {
            payingTokenMode = .onlySol
        }
        return .init(payingTokenMode: payingTokenMode)
    }

    func getPoolPair(
        from sourceMint: String,
        to destinationMint: String,
        amount: UInt64,
        as inputMode: Swap.InputMode
    ) -> Single<[Swap.PoolsPair]> {
        orcaSwap.getTradablePoolsPairs(fromMint: sourceMint, toMint: destinationMint)
            .map { result in result.map { $0.toPoolsPair() } }
    }

    func getFees(
        sourceAddress: String,
        sourceMint: String,
        availableSourceMintAddresses: [String],
        destinationAddress: String?,
        destinationToken: SolanaSDK.Token,
        bestPoolsPair: Swap.PoolsPair?,
        payingTokenMint: String?,
        inputAmount: Double?,
        slippage: Double,
        lamportsPerSignature: UInt64,
        minRentExempt: UInt64
    ) -> Single<Swap.FeeInfo> {
        guard let bestPoolsPair = bestPoolsPair as? PoolsPair else { return .error(Swap.Error.incompatiblePoolsPair) }
        // Network fees
        let networkFeesRequest: Single<[PayingFee]>
        if isUsingNativeSwap(sourceAddress: sourceAddress, payingTokenMint: payingTokenMint) {
            // Network fee for swapping natively
            do {
                networkFeesRequest = .just(
                    try getNetworkFeesForSwappingNatively(
                        availableSourceMintAddresses: availableSourceMintAddresses,
                        sourceAddress: sourceAddress,
                        destinationAddress: destinationAddress,
                        destinationToken: destinationToken,
                        poolsPair: bestPoolsPair.orcaPoolPair,
                        inputAmount: inputAmount,
                        slippage: slippage,
                        lamportsPerSignature: lamportsPerSignature,
                        minRentExempt: minRentExempt
                    )
                )
            } catch {
                networkFeesRequest = .error(error)
            }
            
        } else {
            // Network fee for swapping via relay program
            networkFeesRequest = getNetworkFeesForSwappingViaRelayProgram(
                sourceMint: sourceMint,
                destinationAddress: destinationAddress,
                destinationToken: destinationToken
            )
        }
        
        return networkFeesRequest
            .map {[weak self] networkFees in
                guard let self = self else {throw SolanaSDK.Error.unknown}
                
                // Liquidity provider fee
                let liquidityProviderFees = try self.getLiquidityProviderFees(
                    poolsPair: bestPoolsPair.orcaPoolPair,
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
    ) -> Single<SolanaSDK.Lamports?> {
        if payingTokenMint == SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString {
            return .just(networkFee.total)
        }
        return relayService!.calculateFeeInPayingToken(feeInSOL: networkFee.total, payingFeeTokenMint: payingTokenMint)
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
        guard let poolsPair = poolsPair as? PoolsPair else { return .error(Swap.Error.incompatiblePoolsPair) }
        
        // SWAP NATIVELY
        if isUsingNativeSwap(sourceAddress: sourceAddress, payingTokenMint: payingTokenMint) {
            return swapNatively(
                poolsPair: poolsPair.orcaPoolPair,
                sourceAddress: sourceAddress,
                destinationAddress: destinationAddress,
                amount: amount,
                slippage: slippage
            )
        }
        
        // SWAP VIA RELAY PROGRAM
        else {
            return swapViaRelayProgram(
                sourceAddress: sourceAddress,
                sourceTokenMint: sourceTokenMint,
                destinationAddress: destinationAddress,
                destinationTokenMint: destinationTokenMint,
                payingTokenAddress: payingTokenAddress,
                payingTokenMint: payingTokenMint,
                poolsPair: poolsPair.orcaPoolPair,
                amount: amount,
                slippage: slippage
            )
        }
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
    private func isUsingNativeSwap(
        sourceAddress: String,
        payingTokenMint: String?
    ) -> Bool {
        sourceAddress == accountStorage.account?.publicKey.base58EncodedString ||
            payingTokenMint == SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString
    }
    
    private func getLiquidityProviderFees(
        poolsPair: OrcaSwap.PoolsPair,
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
        
        if destinationAddress != nil, let destinationToken = destinationToken {
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
    
    private func getNetworkFeesForSwappingNatively(
        availableSourceMintAddresses: [String],
        sourceAddress: String,
        destinationAddress: String?,
        destinationToken: SolanaSDK.Token?,
        poolsPair: OrcaSwap.PoolsPair,
        inputAmount: Double?,
        slippage: Double,
        lamportsPerSignature: UInt64,
        minRentExempt: UInt64
    ) throws -> [PayingFee] {
        let networkFees = try orcaSwap.getNetworkFees(
            myWalletsMints: availableSourceMintAddresses,
            fromWalletPubkey: sourceAddress,
            toWalletPubkey: destinationAddress,
            bestPoolsPair: poolsPair,
            inputAmount: inputAmount,
            slippage: slippage,
            lamportsPerSignature: lamportsPerSignature,
            minRentExempt: minRentExempt
        )

        var allFees = [PayingFee]()
        
        allFees.append(
            .init(
                type: .transactionFee,
                lamports: networkFees.transaction,
                token: .nativeSolana
            )
        )
        
        if networkFees.accountBalances > 0 {
            allFees.append(
                .init(
                    type: .accountCreationFee(token: destinationToken?.symbol),
                    lamports: networkFees.accountBalances,
                    token: .nativeSolana
                )
            )
        }
        
        return allFees
    }
    
    private func getNetworkFeesForSwappingViaRelayProgram(
        sourceMint: String,
        destinationAddress: String?,
        destinationToken: SolanaSDK.Token
    ) -> Single<[PayingFee]> {
        relayService!.calculateSwappingNetworkFees(
            sourceTokenMint: sourceMint,
            destinationTokenMint: destinationToken.address,
            destinationAddress: destinationAddress
        )
            .flatMap { [weak self] networkFee -> Single<SolanaSDK.FeeAmount> in
                guard let self = self else { throw SolanaSDK.Error.unknown }
                return self.relayService!.calculateNeededTopUpAmount(expectedFee: networkFee)
            }
            .map { [weak self] neededTopUpAmount in
                guard let self = self else {throw FeeRelayer.Error.unknown}
                
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
                
                allFees.append(
                    .init(
                        type: .transactionFee,
                        lamports: neededTopUpAmount.transaction,
                        token: .nativeSolana,
                        toString: nil,
                        isFree: isFree,
                        info: info
                    )
                )
                
                allFees.append(
                    .init(
                        type: .accountCreationFee(token: destinationToken.symbol),
                        lamports: neededTopUpAmount.accountBalances,
                        token: .nativeSolana
                    )
                )
                
                return allFees
            }
    }
    
    private func swapNatively(
        poolsPair: OrcaSwap.PoolsPair,
        sourceAddress: String,
        destinationAddress: String?,
        amount: UInt64,
        slippage: Double
    ) -> Single<[String]> {
        guard let decimals = poolsPair[0].getTokenADecimals() else {
            return .error(OrcaSwapError.invalidPool)
        }
        
        return orcaSwap.swap(
            fromWalletPubkey: sourceAddress,
            toWalletPubkey: destinationAddress,
            bestPoolsPair: poolsPair,
            amount: amount.convertToBalance(decimals: decimals),
            slippage: slippage,
            isSimulation: false
        ).map { response in [response.transactionId] }
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
        slippage: Double
    ) -> Single<[String]> {
        guard let feeRelay = relayService else { return .error(SolanaSDK.Error.other("Fee relay is not ready")) }

        // if it's spl -> spl or sol -> spl, then use relay
        var payingFeeToken: FeeRelayer.Relay.TokenInfo?
        if let payingTokenAddress = payingTokenAddress, let payingTokenMint = payingTokenMint {
            payingFeeToken = FeeRelayer.Relay.TokenInfo(address: payingTokenAddress, mint: payingTokenMint)
        }
        return feeRelay.prepareSwapTransaction(
            sourceToken: FeeRelayer.Relay.TokenInfo(address: sourceAddress, mint: sourceTokenMint),
            destinationTokenMint: destinationTokenMint,
            destinationAddress: destinationAddress,
            payingFeeToken: payingFeeToken,
            swapPools: poolsPair,
            inputAmount: amount,
            slippage: slippage
        ).flatMap { [weak self] transaction in
            guard let feeRelay = self?.relayService else { throw SolanaSDK.Error.other("Fee relay is deallocated") }
            return feeRelay.topUpAndRelayTransaction(preparedTransaction: transaction, payingFeeToken: payingFeeToken)
        }
    }
}

extension OrcaSwap.PoolsPair {
    fileprivate func toPoolsPair() -> SwapServiceWithRelayImpl.PoolsPair { .init(orcaPoolPair: self) }
}
