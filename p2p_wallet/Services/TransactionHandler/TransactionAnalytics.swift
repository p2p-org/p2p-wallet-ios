//
// Created by Giang Long Tran on 24.03.2022.
//

import AnalyticsManager
import Foundation
import Resolver
import RxSwift

class SwapTransactionAnalytics {
    let disposeBag = DisposeBag()
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var transactionHandler: TransactionHandlerType

    init() {
        transactionHandler
            .onNewTransaction
            .subscribe(onNext: { [weak self] trx, index in
                if trx.rawTransaction.isSwap { self?.observer(index: index) }
            })
            .disposed(by: disposeBag)
    }

    func observer(index: TransactionHandler.TransactionIndex) {
        Observable<PendingTransaction>.create { [unowned self] observer in
            let localDisposable = transactionHandler.observeTransaction(transactionIndex: index)
                .subscribe(onNext: { trx in
                    guard let trx = trx else {
                        observer.on(.completed)
                        return
                    }

                    observer.on(.next(trx))
                    switch trx.status {
                    case .finalized, .error:
                        observer.on(.completed)
                    default:
                        break
                    }

                })

            return Disposables.create {
                localDisposable.dispose()
            }
        }
        .distinctUntilChanged(at: \.status.rawValue)
        .withPrevious()
        .subscribe(onNext: { prevTrx, trx in
            guard let rawTrx = trx.rawTransaction as? ProcessTransaction.SwapTransaction else { return }

            switch trx.status {
            case .sending:
                self.analyticsManager.log(
                    event: .swapUserConfirmed(
                        tokenAName: rawTrx.sourceWallet.token.symbol,
                        tokenBName: rawTrx.destinationWallet.token.symbol,
                        swapSum: rawTrx.amount,
                        swapMAX: rawTrx.metaInfo.swapMAX,
                        swapUSD: rawTrx.metaInfo.swapUSD,
                        priceSlippage: rawTrx.slippage,
                        feesSource: rawTrx.payingWallet?.token.name ?? "Unknown"
                    )
                )
            case let .confirmed(confirmation):
                if confirmation == 0 {
                    self.analyticsManager.log(
                        event: .swapStarted(
                            tokenAName: rawTrx.sourceWallet.token.symbol,
                            tokenBName: rawTrx.destinationWallet.token.symbol,
                            swapSum: rawTrx.amount,
                            swapMAX: rawTrx.metaInfo.swapMAX,
                            swapUSD: rawTrx.metaInfo.swapUSD,
                            priceSlippage: rawTrx.slippage,
                            feesSource: rawTrx.payingWallet?.token.name ?? "Unknown"
                        )
                    )
                } else if prevTrx?.status.numberOfConfirmations == 0 {
                    self.analyticsManager.log(
                        event: .swapApprovedByNetwork(
                            tokenAName: rawTrx.sourceWallet.token.symbol,
                            tokenBName: rawTrx.destinationWallet.token.symbol,
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
                    event: .swapCompleted(
                        tokenAName: rawTrx.sourceWallet.token.symbol,
                        tokenBName: rawTrx.destinationWallet.token.symbol,
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
        })
        .disposed(by: disposeBag)
    }
}
