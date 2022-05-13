//
//  TransactionViewController.swift
//  p2p_wallet
//
//  Created by Ivan on 17.04.2022.
//

import BEPureLayout
import RxCocoa

extension History {
    final class TransactionViewController: WLModalViewController {
        @Injected private var notificationService: NotificationService

        private let viewModel: TransactionViewModel

        init(viewModel: TransactionViewModel) {
            self.viewModel = viewModel
        }

        override func build() -> UIView {
            BEBuilder(driver: viewModel.viewIO.1.state) { [weak self] state in
                guard let self = self else { return UIView() }
                let (input, _) = self.viewModel.viewIO

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
                    self?.presentationController?.containerViewWillLayoutSubviews()
                }

                switch state {
                case let .single(model):
                    return TransactionView().setup { view in
                        view.rx.model.onNext(model)
                        view.rx
                            .transactionIdClicked
                            .bind(to: input.transactionIdClicked)
                            .disposed(by: self.disposeBag)
                        view.rx
                            .doneClicked
                            .bind(to: input.doneClicked)
                            .disposed(by: self.disposeBag)
                        view.rx
                            .transactionDetailClicked
                            .bind(to: input.transactionDetailClicked)
                            .disposed(by: self.disposeBag)
                        view.rx
                            .tryAgainClicked
                            .bind(to: input.tryAgain)
                            .disposed(by: self.disposeBag)
                    }
                case let .pending(model):
                    return TransactionPendingView(height: 654).setup { view in
                        view.rx.model.onNext(model)
                        view.rx
                            .doneClicked
                            .bind(to: input.doneClicked)
                            .disposed(by: self.disposeBag)
                        view.rx
                            .transactionDetailClicked
                            .bind(to: input.transactionDetailClicked)
                            .disposed(by: self.disposeBag)
                    }
                }
            }
        }

        override func bind() {
            super.bind()

            let (input, output) = viewModel.viewIO

            rx.viewWillAppear
                .take(1)
                .mapToVoid()
                .bind(to: input.viewDidLoad)
                .disposed(by: disposeBag)
            rx.viewWillAppear
                .mapToVoid()
                .bind(to: input.viewWillAppear)
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
