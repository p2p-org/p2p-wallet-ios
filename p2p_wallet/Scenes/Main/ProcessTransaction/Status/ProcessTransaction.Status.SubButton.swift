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
            bind()
        }
        
        private func bind() {
            viewModel.pendingTransactionDriver
                .map {$0.status.error == nil}
                .map {$0 ? L10n.makeAnotherTransaction: L10n.tryAgain}
                .drive(self.rx.text)
                .disposed(by: disposeBag)
        }
    }
}
