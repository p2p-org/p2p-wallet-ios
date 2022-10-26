//
// Created by Giang Long Tran on 24.03.2022.
//

import AnalyticsManager
import Combine
import Foundation
import Resolver

class SwapTransactionAnalytics {
    private var subscriptions = [AnyCancellable]()
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var transactionHandler: TransactionHandlerType

    init() {
        transactionHandler
            .onNewTransaction
            .sink { [weak self] trx, index in
                if trx.rawTransaction.isSwap { self?.observer(index: index) }
            }
            .store(in: &subscriptions)
    }

    func observer(index: TransactionHandler.TransactionIndex) {
        transactionHandler.observeTransaction(transactionIndex: index)
            .flatMap { trx -> AnyPublisher<PendingTransaction, Never> in
                guard let trx = trx else {
                    return Empty(completeImmediately: true)
                        .eraseToAnyPublisher()
                }
                switch trx.status {
                case .finalized, .error:
                    return Empty(completeImmediately: true)
                        .eraseToAnyPublisher()
                default:
                    return Just(trx)
                        .eraseToAnyPublisher()
                }
            }
            .removeDuplicates { p1, p2 in
                p1.status.rawValue != p2.status.rawValue
            }
            .withPrevious()
            .sink { prevTrx, trx in
                guard let rawTrx = trx.rawTransaction as? ProcessTransaction.SwapTransaction else { return }

                switch trx.status {
                case .sending:
                    self.analyticsManager.log(
                        event: AmplitudeEvent.swapUserConfirmed(
                            tokenA_Name: rawTrx.sourceWallet.token.symbol,
                            tokenB_Name: rawTrx.destinationWallet.token.symbol,
                            swapSum: rawTrx.amount,
                            swapMAX: rawTrx.metaInfo.swapMAX,
                            swapUSD: rawTrx.metaInfo.swapUSD,
                            priceSlippage: rawTrx.slippage,
                            feesSource: rawTrx.payingWallet?.token.name ?? "Unknown"
                        )
                    )
                case let .confirmed(confirmation, _):
                    if confirmation == 0 {
                        self.analyticsManager.log(
                            event: AmplitudeEvent.swapStarted(
                                tokenA_Name: rawTrx.sourceWallet.token.symbol,
                                tokenB_Name: rawTrx.destinationWallet.token.symbol,
                                swapSum: rawTrx.amount,
                                swapMAX: rawTrx.metaInfo.swapMAX,
                                swapUSD: rawTrx.metaInfo.swapUSD,
                                priceSlippage: rawTrx.slippage,
                                feesSource: rawTrx.payingWallet?.token.name ?? "Unknown"
                            )
                        )
                    } else if prevTrx?.status.numberOfConfirmations == 0 {
                        self.analyticsManager.log(
                            event: AmplitudeEvent.swapApprovedByNetwork(
                                tokenA_Name: rawTrx.sourceWallet.token.symbol,
                                tokenB_Name: rawTrx.destinationWallet.token.symbol,
                                swapSum: rawTrx.amount,
                                swapMAX: rawTrx.metaInfo.swapMAX,
                                swapUSD: rawTrx.metaInfo.swapUSD,
                                priceSlippage: rawTrx.slippage,
                                feesSource: rawTrx.payingWallet?.token.name ?? "Unknown"
                            )
                        )
                    }
                case .finalized:
                    self.analyticsManager.log(
                        event: AmplitudeEvent.swapApprovedByNetwork(
                            tokenA_Name: rawTrx.sourceWallet.token.symbol,
                            tokenB_Name: rawTrx.destinationWallet.token.symbol,
                            swapSum: rawTrx.amount,
                            swapMAX: rawTrx.metaInfo.swapMAX,
                            swapUSD: rawTrx.metaInfo.swapUSD,
                            priceSlippage: rawTrx.slippage,
                            feesSource: rawTrx.payingWallet?.token.name ?? "Unknown"
                        )
                    )
                default:
                    break
                }
            }
            .store(in: &subscriptions)
    }
}
