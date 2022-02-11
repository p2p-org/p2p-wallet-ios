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
    private var feeRelay: FeeRelayerRelayType?
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
            feeRelay = try FeeRelayer.Relay(
                apiClient: feeRelayApi,
                solanaClient: solanaClient,
                accountStorage: accountStorage,
                orcaSwapClient: orcaSwap
            )

            return .zip(
                orcaSwap.load(),
                feeRelay!.load()
            )
        }
        catch {
            return .error(error)
        }
    }

    func getSwapInfo(from sourceToken: SolanaSDK.Token, to destinationToken: SolanaSDK.Token) -> Swap.SwapInfo {
        // Determine a mode for paying fee
        var payingTokenMode: Swap.PayingTokenMode = .any
        if sourceToken.isNativeSOL && !destinationToken.isNativeSOL {
            payingTokenMode = .onlySol
        }
        else if !sourceToken.isNativeSOL && destinationToken.isNativeSOL {
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
        availableSourceMintAddresses: [String],
        destinationAddress: String?,
        destinationToken: SolanaSDK.Token?,
        bestPoolsPair: Swap.PoolsPair?,
        inputAmount: Double?,
        slippage: Double,
        lamportsPerSignature: UInt64,
        minRentExempt: UInt64
    ) -> Single<Swap.FeeInfo> {
        guard let bestPoolsPair = bestPoolsPair as? PoolsPair else { return .error(Swap.Error.incompatiblePoolsPair) }
        guard let feeRelay = feeRelay else { return .error(Swap.Error.feeRelayIsNotReady) }

        do {
            let fees = try orcaSwap.getFees(
                myWalletsMints: availableSourceMintAddresses,
                fromWalletPubkey: sourceAddress,
                toWalletPubkey: destinationAddress,
                bestPoolsPair: bestPoolsPair.orcaPoolPair,
                inputAmount: inputAmount,
                slippage: slippage,
                lamportsPerSignature: lamportsPerSignature,
                minRentExempt: minRentExempt
            )

            var allFees = [PayingFee]()

            if destinationAddress != nil, let destinationToken = destinationToken {
                if fees.liquidityProviderFees.count == 1 {
                    allFees.append(
                        .init(
                            type: .liquidityProviderFee,
                            lamports: fees.liquidityProviderFees.first!,
                            token: destinationToken
                        )
                    )
                }
                else if fees.liquidityProviderFees.count == 2 {
                    let intermediaryTokenName = bestPoolsPair.orcaPoolPair[0].tokenBName
                    if let decimals = bestPoolsPair.orcaPoolPair[0].getTokenBDecimals() {
                        allFees.append(
                            .init(
                                type: .liquidityProviderFee,
                                lamports: fees.liquidityProviderFees.first!,
                                token: .unsupported(mint: nil, decimals: decimals, symbol: intermediaryTokenName)
                            )
                        )
                    }

                    allFees.append(
                        .init(
                            type: .liquidityProviderFee,
                            lamports: fees.liquidityProviderFees.last!,
                            token: destinationToken
                        )
                    )
                }
            }

            if let creationFee = fees.accountCreationFee {
                allFees.append(
                    .init(
                        type: .accountCreationFee(token: destinationToken?.symbol),
                        lamports: creationFee,
                        token: .nativeSolana
                    )
                )
            }

            let transactionFee = PayingFee(
                type: .transactionFee,
                lamports: fees.transactionFees,
                token: .nativeSolana
            )

            return feeRelay.getFreeTransactionFeeLimit(useCache: true)
                .flatMap { info in
                    if info.isFreeTransactionFeeAvailable(transactionFee: fees.transactionFees) {
                        allFees.append(
                            .init(
                                type: .transactionFee,
                                lamports: fees.transactionFees,
                                token: .nativeSolana,
                                toString: nil,
                                isFree: true,
                                info: .init(
                                    alertTitle: L10n.thereAreFreeTransactionsLeftForToday(info.maxUsage - info.currentUsage),
                                    alertDescription: L10n.OnTheSolanaNetworkTheFirst100TransactionsInADayArePaidByP2P.Org.subsequentTransactionsWillBeChargedBasedOnTheSolanaBlockchainGasFee,
                                    payBy: L10n.PaidByP2p.org
                                )
                            )
                        )
                    }
                    else {
                        allFees.append(transactionFee)
                    }
                    return .just(Swap.FeeInfo(fees: allFees))
                }
                .catch { [weak self] error in
                    self?.notification.showInAppNotification(.error(error))
                    allFees.append(transactionFee)
                    return .just(Swap.FeeInfo(fees: allFees))
                }
        }
        catch {
            return .error(error)
        }
    }

    public func findPosibleDestinationMints(fromMint: String) throws -> [String] { try orcaSwap.findPosibleDestinationMints(fromMint: fromMint) }

    func swap(
        sourceAddress: String,
        sourceTokenMint: String?,
        destinationAddress: String?,
        destinationTokenMint: String?,
        payingTokenAddress: String,
        payingTokenMint: String,
        poolsPair: Swap.PoolsPair,
        amount: UInt64,
        slippage: Double
    ) -> Single<[String]> {
        guard let poolsPair = poolsPair as? PoolsPair else { return .error(Swap.Error.incompatiblePoolsPair) }

        // handle spl -> sol case, we use simple orca swap
        if destinationAddress == accountStorage.account?.publicKey.base58EncodedString || payingTokenMint == SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString {
            guard let decimals = poolsPair.orcaPoolPair[0].getTokenADecimals() else {
                return .error(OrcaSwapError.invalidPool)
            }

            return orcaSwap.swap(
                fromWalletPubkey: sourceAddress,
                toWalletPubkey: destinationAddress,
                bestPoolsPair: poolsPair.orcaPoolPair,
                amount: amount.convertToBalance(decimals: decimals),
                slippage: slippage,
                isSimulation: false
            ).map { response in [response.transactionId] }
        }

        guard let feeRelay = feeRelay else { return .error(SolanaSDK.Error.other("Fee relay is not ready")) }
        guard let sourceTokenMint = sourceTokenMint else { return .error(SolanaSDK.Error.other("Invalid source mint address")) }
        guard let destinationTokenMint = destinationTokenMint else { return .error(SolanaSDK.Error.other("Invalid destination mint address")) }

        // if it's spl -> spl or sol -> spl, then use relay
        let payingFeeToken = FeeRelayer.Relay.TokenInfo(address: payingTokenAddress, mint: payingTokenMint)
        return feeRelay.prepareSwapTransaction(
            sourceToken: FeeRelayer.Relay.TokenInfo(address: sourceAddress, mint: sourceTokenMint),
            destinationTokenMint: destinationTokenMint,
            destinationAddress: destinationAddress,
            payingFeeToken: payingFeeToken,
            swapPools: poolsPair.orcaPoolPair,
            inputAmount: amount,
            slippage: slippage
        ).flatMap { [weak self] transaction in
            guard let feeRelay = self?.feeRelay else { throw SolanaSDK.Error.other("Fee relay is deallocated") }
            return feeRelay.topUpAndRelayTransaction(preparedTransaction: transaction, payingFeeToken: payingFeeToken)
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
}

extension OrcaSwap.PoolsPair {
    fileprivate func toPoolsPair() -> SwapServiceWithRelayImpl.PoolsPair { .init(orcaPoolPair: self) }
}
