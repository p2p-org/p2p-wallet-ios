//
// Created by Giang Long Tran on 24.03.2022.
//

import AnalyticsManager
import Foundation
import Combine

class SwapTransactionAnalytics {
    // MARK: - Properties
    
    var subscriptions = Set<AnyCancellable>()
    let analyticsManager: AnalyticsManager
    let transactionHandler: TransactionHandlerType

    // MARK: - Initializer

    init(analyticsManager: AnalyticsManager, transactionHandler: TransactionHandlerType) {
        self.analyticsManager = analyticsManager
        self.transactionHandler = transactionHandler

        transactionHandler
            .onNewTransaction
            .receive(on: DispatchQueue.main)
            .filter {
                $0.0.rawTransaction is SwapRawTransactionType
            }
            .sink(receiveValue: { [weak self] trx, index in
                self?.observer(index: index)
            })
            .store(in: &subscriptions)
    }

    // MARK: - Methods

    func observer(index: TransactionHandler.TransactionIndex) {
        transactionHandler.observeTransaction(transactionIndex: index)
        .compactMap { $0 }
        .withPrevious()
        .sink(receiveValue: { [weak self] param in
            let prevTrx = param.previous
            let trx = param.current
            guard let self else { return }
            guard let rawTrx = trx.rawTransaction as? SwapRawTransactionType, !available(.jupiterSwapEnabled) else { return }
            // WARNING: This swap analytics is only for old swap
            switch trx.status {
            case .sending:
                self.analyticsManager.log(
                    event: .swapUserConfirmed(
                        tokenA_Name: rawTrx.sourceWallet.token.symbol,
                        tokenB_Name: rawTrx.destinationWallet.token.symbol,
                        swapSum: rawTrx.fromAmount,
                        swapMAX: rawTrx.metaInfo.swapMAX,
                        swapUSD: rawTrx.metaInfo.swapUSD,
                        priceSlippage: rawTrx.slippage,
                        feesSource: rawTrx.payingFeeWallet?.token.name ?? "Unknown"
                    )
                )
            case let .confirmed(confirmation):
                if confirmation == 0 {
                    self.analyticsManager.log(
                        event: .swapStarted(
                            tokenA_Name: rawTrx.sourceWallet.token.symbol,
                            tokenB_Name: rawTrx.destinationWallet.token.symbol,
                            swapSum: rawTrx.fromAmount,
                            swapMAX: rawTrx.metaInfo.swapMAX,
                            swapUSD: rawTrx.metaInfo.swapUSD,
                            priceSlippage: rawTrx.slippage,
                            feesSource: rawTrx.payingFeeWallet?.token.name ?? "Unknown"
                        )
                    )
                } else if prevTrx?.status.numberOfConfirmations == 0 {
                    self.analyticsManager.log(
                        event: .swapApprovedByNetwork(
                            tokenA_Name: rawTrx.sourceWallet.token.symbol,
                            tokenB_Name: rawTrx.destinationWallet.token.symbol,
                            swapSum: rawTrx.fromAmount,
                            swapMAX: rawTrx.metaInfo.swapMAX,
                            swapUSD: rawTrx.metaInfo.swapUSD,
                            priceSlippage: rawTrx.slippage,
                            feesSource: rawTrx.payingFeeWallet?.token.name ?? "Unknown"
                        )
                    )
                }
            case .finalized:
                self.analyticsManager.log(
                    event: .swapCompleted(
                        tokenA_Name: rawTrx.sourceWallet.token.symbol,
                        tokenB_Name: rawTrx.destinationWallet.token.symbol,
                        swapSum: rawTrx.fromAmount,
                        swapMAX: rawTrx.metaInfo.swapMAX,
                        swapUSD: rawTrx.metaInfo.swapUSD,
                        priceSlippage: rawTrx.slippage,
                        feesSource: rawTrx.payingFeeWallet?.token.name ?? "Unknown"
                    )
                )
            default:
                break
            }
        })
        .store(in: &subscriptions)
    }
}
