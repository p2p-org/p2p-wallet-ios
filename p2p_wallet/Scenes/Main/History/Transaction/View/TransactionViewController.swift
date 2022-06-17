//
//  TransactionViewController.swift
//  p2p_wallet
//
//  Created by Ivan on 17.04.2022.
//

import BEPureLayout
import Resolver
import RxCocoa

extension History {
    final class TransactionViewController: WLModalViewController {
        @Injected private var notificationService: NotificationService

        private lazy var customView = TransactionView()

        private let viewModel: TransactionViewModel

        init(viewModel: TransactionViewModel) {
            self.viewModel = viewModel
        }

        override func build() -> UIView {
            customView
        }

        override func bind() {
            super.bind()

            let (input, output) = viewModel.viewIO

            rx.viewWillAppear
                .take(1)
                .mapTo(())
                .bind(to: input.viewDidLoad)
                .disposed(by: disposeBag)
            customView.rx
                .transactionIdClicked
                .bind(to: input.transactionIdClicked)
                .disposed(by: disposeBag)
            customView.rx
                .doneClicked
                .bind(to: input.doneClicked)
                .disposed(by: disposeBag)
            customView.rx
                .transactionDetailClicked
                .bind(to: input.transactionDetailClicked)
                .disposed(by: disposeBag)

            output.model
                .drive(customView.rx.model)
                .disposed(by: disposeBag)
            output.copied
                .drive(onNext: { [weak self] in
                    self?.notificationService.showInAppNotification(.done(L10n.copiedToClipboard))
                })
                .disposed(by: disposeBag)

            // TODO: - Move to coordinator later

            let (_, coordinatorOutput) = viewModel.coordIO

            coordinatorOutput.done
                .drive(onNext: { [unowned self] in
                    dismiss(animated: true)
                })
                .disposed(by: disposeBag)
            coordinatorOutput.showWebView
                .drive(onNext: { [unowned self] url in
                    showWebsite(url: url)
                })
                .disposed(by: disposeBag)
        }
    }
}
