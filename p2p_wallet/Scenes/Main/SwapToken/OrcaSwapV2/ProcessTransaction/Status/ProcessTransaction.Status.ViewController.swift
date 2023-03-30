//
//  ProcessTransaction.Status.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/12/2021.
//

import BEPureLayout
import FeeRelayerSwift
import KeyAppUI
import UIKit
import RxSwift

extension ProcessTransaction.Status {
    class ViewController: WLModalViewController {
        // MARK: - Dependencies

        private let viewModel: ProcessTransactionViewModelType
        private let disposeBag = DisposeBag()

        // MARK: - Handlers

        var doneHandler: (() -> Void)?

        // MARK: - Initializer

        init(viewModel: ProcessTransactionViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        // MARK: - Methods

        override func build() -> UIView {
            BEContainer {
                BEVStack(spacing: 4) {
                    // Header label
                    HeaderLabel(viewModel: viewModel)
                        .padding(.init(x: 18, y: 0))

                    // Detail
                    UILabel(
                        text: "0.00227631 renBTC → DkmT...JnBw",
                        textSize: 15,
                        textColor: .textSecondary,
                        numberOfLines: 0,
                        textAlignment: .center
                    )
                        .setup { label in
                            label.text = viewModel.getMainDescription()
                        }
                        .padding(.init(all: 18, excludingEdge: .top))

                    // Loader
                    BEZStack {
                        // Process indicator
                        BEZStackPosition {
                            ProgressView()
                                .setup { progressView in
                                    viewModel.pendingTransactionDriver
                                        .map(\.status)
                                        .drive(progressView.rx.transactionStatus)
                                        .disposed(by: disposeBag)
                                }
                                .centered(.vertical)
                        }

                        // Icon
                        BEZStackPosition {
                            UIImageView(width: 44, height: 44)
                                .setup { imageView in
                                    viewModel.pendingTransactionDriver
                                        .map(\.status)
                                        .map { status -> UIImage in
                                            switch status {
                                            case .sending, .confirmed:
                                                return .squircleTransactionProcessing
                                            case .finalized:
                                                return .squircleTransactionCompleted
                                            case .error:
                                                return .squircleTransactionError
                                            }
                                        }
                                        .drive(imageView.rx.image)
                                        .disposed(by: disposeBag)
                                }
                                .centered(.horizontal)
                        }
                    }
                    .padding(.init(only: .bottom, inset: 18))

                    // Green alert (shown only when top up is finished but transaction is not)
                    UIView.greenBannerView {
                        UILabel(text: nil, textSize: 13, numberOfLines: 0)
                            .setup { label in
                                viewModel.pendingTransactionDriver
                                    .map { pendingTransaction -> String? in
                                        // top up finished but transaction throws
                                        if pendingTransaction.status.error as? FeeRelayerError == .topUpSuccessButTransactionThrows,
                                           let swapTransaction = pendingTransaction.rawTransaction as? SwapRawTransactionType,
                                           let payingFeeWallet = swapTransaction.payingFeeWallet
                                        {
                                            let fee = swapTransaction.feeAmount.total
                                                .convertToBalance(
                                                    decimals: payingFeeWallet.token.decimals
                                                ).toString()
                                                + " "
                                            + payingFeeWallet.token.symbol
                                            
                                            return L10n
                                                .theFeeWasReservedSoYouWouldnTPayItAgainTheNextTimeYouCreatedATransactionOfTheSameType(
                                                    fee
                                                )
                                        }
                                        
                                        // transaction has been confirmed in solana chain but hasn't been confirmed in bitcoin chain
                                        return L10n
                                            .theFeeWasReservedSoYouWouldnTPayItAgainTheNextTimeYouCreatedATransactionOfTheSameType(
                                                ""
                                            ) // placeholder
                                    }
                                    .drive(label.rx.text)
                                    .disposed(by: disposeBag)
//
                            }
                    }
                    .padding(.init(top: 0, left: 18, bottom: 14, right: 18))
                    .setup { view in
                        viewModel.pendingTransactionDriver
                            .map { pendingTransaction -> Bool in
                                // top up finished but transaction throws
                                if pendingTransaction.status.error as? FeeRelayerError == .topUpSuccessButTransactionThrows {
                                    return false
                                }
                                
                                // transaction has been confirmed in solana chain but hasn't been confirmed in bitcoin chain
                                return true
                            }
                            .drive(view.rx.isHidden)
                            .disposed(by: disposeBag)
                    }

                    // Transaction ID
                    BEHStack(spacing: 4, alignment: .top, distribution: .fill) {
                        UILabel(text: L10n.transactionID, textSize: 15, textColor: .textSecondary)

                        BEVStack(spacing: 4, alignment: .fill, distribution: .fill) {
                            BEHStack(spacing: 4, alignment: .center, distribution: .fill) {
                                UILabel(
                                    text: "4gj7UK2mG...NjweNS39N",
                                    textSize: 15,
                                    textAlignment: .right
                                )
                                    .setup { label in
                                        viewModel.pendingTransactionDriver
                                            .map {
                                                $0.transactionId?
                                                    .truncatingMiddle(numOfSymbolsRevealed: 9,
                                                                      numOfSymbolsRevealedInSuffix: 9)
                                            }
                                            .drive(label.rx.text)
                                            .disposed(by: disposeBag)
                                    }
                                UIImageView(
                                    width: 16,
                                    height: 16,
                                    image: .transactionShowInExplorer,
                                    tintColor: .textSecondary
                                )
                            }
                            UILabel(
                                text: L10n.tapToViewInExplorer,
                                textSize: 15,
                                textColor: .textSecondary,
                                numberOfLines: 0,
                                textAlignment: .right
                            )
                        }
                        .onTap { [weak self] in
                            self?.viewModel.navigate(to: .explorer)
                        }
                    }
                    .padding(.init(top: 0, left: 18, bottom: 36, right: 18))
                    .setup { view in
                        viewModel.pendingTransactionDriver
                            .map { $0.transactionId == nil }
                            .drive(view.rx.isHidden)
                            .disposed(by: disposeBag)
                    }

                    // Buttons
                    BEVStack(spacing: 10) {
                        TextButton(
                            title: L10n.done,
                            style: .primary,
                            size: .large,
                            leading: .buttonCheckSmall
                        ).onPressed { [weak self] _ in
                            self?.dismiss(animated: true) { [weak self] in
                                self?.doneHandler?()
                            }
                        }
                    }
                    .padding(.init(x: 18, y: 0))
                }
                .padding(.init(x: 0, y: 18))
            }
        }

        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)

            viewModel.pendingTransactionDriver
                .map { $0.transactionId == nil }
                .drive(onNext: { [weak self] _ in
                    UIView.animate(withDuration: 0.3) {
                        self?.updatePresentationLayout()
                    }
                })
                .disposed(by: disposeBag)
        }

        private func navigate(to scene: ProcessTransaction.NavigatableScene?) {
            switch scene {
            case .explorer:
                showWebsite(url: "https://explorer.solana.com/tx/" + (viewModel.transactionID ?? ""))
            default:
                break
            }
        }
    }
}
