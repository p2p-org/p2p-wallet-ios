//
// Created by Giang Long Tran on 24.03.2022.
//

import Foundation
import RxSwift

class SwapTransactionAnalytics {
    let disposeBag = DisposeBag()
    let analyticsManager: AnalyticsManager
    let transactionHandler: TransactionHandlerType

    init(analyticsManager: AnalyticsManager, transactionHandler: TransactionHandlerType) {
        self.analyticsManager = analyticsManager
        self.transactionHandler = transactionHandler

        transactionHandler
            .onNewTransaction
            .subscribe(onNext: { [weak self] trx, index in
                print(trx.rawTransaction.isSwap, index)
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
        .subscribe(onNext: { trx in
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
            case .confirmed:
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
