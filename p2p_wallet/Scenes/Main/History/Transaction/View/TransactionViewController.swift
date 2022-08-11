//
//  TransactionViewController.swift
//  p2p_wallet
//
//  Created by Ivan on 17.04.2022.
//

import BEPureLayout
import Combine
import Resolver

extension History {
    final class TransactionViewController: WLModalViewController {
        @Injected private var notificationService: NotificationService

        private lazy var customView = TransactionView()
        private var subscriptions = [AnyCancellable]()

        private let viewModel: TransactionViewModel
        private var viewAppeared: Bool = false

        init(viewModel: TransactionViewModel) {
            self.viewModel = viewModel
        }

        override func build() -> UIView {
            customView
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            if !viewAppeared {
                viewModel.viewIO.0.viewDidLoad.send()
                viewAppeared = true
            }
        }

        override func bind() {
            super.bind()

            let (input, output) = viewModel.viewIO

            customView.transactionIdClicked
                .sink {
                    input.transactionIdClicked.send()
                }
                .store(in: &subscriptions)
            customView.doneClicked
                .sink {
                    input.doneClicked.send()
                }
                .store(in: &subscriptions)
            customView.transactionDetailClicked
                .sink {
                    input.transactionDetailClicked.send()
                }
                .store(in: &subscriptions)

            output.model
                .map(Optional.init)
                .assign(to: \.model, on: customView)
                .store(in: &subscriptions)

            output.copied
                .sink { [weak self] in
                    self?.notificationService.showInAppNotification(.done(L10n.copiedToClipboard))
                }
                .store(in: &subscriptions)

            // TODO: - Move to coordinator later

            let (_, coordinatorOutput) = viewModel.coordIO

            coordinatorOutput.done
                .sink { [unowned self] in
                    dismiss(animated: true)
                }
                .store(in: &subscriptions)
            coordinatorOutput.showWebView
                .sink { [unowned self] url in
                    showWebsite(url: url)
                }
                .store(in: &subscriptions)
        }
    }
}
