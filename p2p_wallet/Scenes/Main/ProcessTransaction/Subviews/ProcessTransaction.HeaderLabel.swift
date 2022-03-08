//
//  HeaderLabel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 06/03/2022.
//

import Foundation
import RxSwift
import RxCocoa

extension ProcessTransaction {
    final class HeaderLabel: UILabel {
        private let disposeBag = DisposeBag()
        
        func driven(with transactionInfoDriver: Driver<PendingTransaction>) -> Self {
            transactionInfoDriver
                .map { info -> String in
                    let originalText = info.rawTransaction.isSwap ? L10n.theSwapIsBeingProcessed: L10n.theTransactionIsBeingProcessed
                    
                    switch info.status {
                    case .sending, .confirmed:
                        return originalText
                    case .error:
                        return L10n.theTransactionHasBeenRejected
                    case .finalized:
                        switch info.rawTransaction {
                        case let transaction as SendTransaction:
                            return L10n.wasSentSuccessfully(transaction.sender.token.symbol)
                        case let transaction as OrcaSwapTransaction:
                            return L10n.swappedSuccessfully(transaction.sourceWallet.token.symbol, transaction.destinationWallet.token.symbol)
                        default:
                            fatalError()
                        }
                    }
                }
                .drive(rx.text)
                .disposed(by: disposeBag)
            return self
        }
    }
}
