//
//  HeaderLabel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 06/03/2022.
//

import Foundation
import RxCocoa
import RxSwift

extension ProcessTransaction.Status {
    final class HeaderLabel: UILabel {
        private let disposeBag = DisposeBag()
        private let viewModel: ProcessTransactionViewModelType

        init(viewModel: ProcessTransactionViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
            set(
                text: nil,
                textSize: 20,
                weight: .semibold,
                numberOfLines: 0,
                textAlignment: .center
            )
            bind()
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func bind() {
            viewModel.pendingTransactionDriver
                .map { info -> String in
                    let originalText = info.rawTransaction.isSwap ? L10n.theSwapIsBeingProcessed : L10n
                        .theTransactionIsBeingProcessed

                    switch info.status {
                    case .sending, .confirmed:
                        return originalText
                    case let .error(error):
                        if error.readableDescription == L10n.swapInstructionExceedsDesiredSlippageLimit {
                            return L10n.lowSlippageCausedTheSwapToFail
                        }
                        return L10n.theTransactionHasBeenRejected
                    case .finalized:
                        switch info.rawTransaction {
                        case let transaction as ProcessTransaction.SendTransaction:
                            return L10n.wasSentSuccessfully(transaction.sender.token.symbol)
                        case let transaction as ProcessTransaction.OrcaSwapTransaction:
                            return L10n.swappedSuccessfully(
                                transaction.sourceWallet.token.symbol,
                                transaction.destinationWallet.token.symbol
                            )
                        default:
                            fatalError()
                        }
                    }
                }
                .drive(rx.text)
                .disposed(by: disposeBag)
        }
    }
}
