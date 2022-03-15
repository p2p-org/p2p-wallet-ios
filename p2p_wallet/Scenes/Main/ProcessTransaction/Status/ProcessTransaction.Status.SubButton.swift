//
//  ProcessTransaction.SubButton.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/03/2022.
//

import Foundation
import RxSwift

extension ProcessTransaction.Status {
    final class SubButton: WLStepButton {
        private let disposeBag = DisposeBag()
        private let viewModel: ProcessTransactionViewModelType
        
        init(viewModel: ProcessTransactionViewModelType) {
            self.viewModel = viewModel
            super.init(
                enabledBgColor: .clear,
                enabledTintColor: .h5887ff,
                disabledTintColor: .textSecondary,
                text: nil
            )
            
            onTap { [weak self] in
                self?.viewModel.handleErrorRetryOrMakeAnotherTransaction()
            }
            
            bind()
        }
        
        private func bind() {
            viewModel.pendingTransactionDriver
                .map {$0.status.error}
                .map { [weak self] error -> String in
                    guard let error = error else {
                        return self?.viewModel.isSwapping == true ? L10n.makeAnotherSwap : L10n.makeAnotherTransaction
                    }
                    if error.readableDescription == L10n.swapInstructionExceedsDesiredSlippageLimit {
                        return L10n.increaseMaximumPriceSlippage
                    }
                    return L10n.tryAgain
                }
                .drive(self.rx.text)
                .disposed(by: disposeBag)
        }
    }
}
