//
//  ProcessTransaction.Status.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/12/2021.
//

import BEPureLayout
import Combine
import FeeRelayerSwift
import Foundation
import UIKit

extension ProcessTransaction.Status {
    class ViewController: WLModalViewController {
        // MARK: - Dependencies

        private let viewModel: ProcessTransactionViewModelType
        private var subscriptions = [AnyCancellable]()

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
                                    viewModel.pendingTransactionPublisher
                                        .map(\.status)
                                        .map { Optional($0) }
                                        .assign(to: \.transactionStatus, on: progressView)
                                        .store(in: &subscriptions)
                                }
                                .centered(.vertical)
                        }

                        // Icon
                        BEZStackPosition {
                            UIImageView(width: 44, height: 44)
                                .setup { imageView in
                                    viewModel.pendingTransactionPublisher
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
                                        .assign(to: \.image, on: imageView)
                                        .store(in: &subscriptions)
                                }
                                .centered(.horizontal)
                        }
                    }
                    .padding(.init(only: .bottom, inset: 18))

                    // Green alert (shown only when top up is finished but transaction is not)
                    UIView.greenBannerView {
                        UILabel(text: nil, textSize: 13, numberOfLines: 0)
                            .setup { label in
                                viewModel.pendingTransactionPublisher
                                    .map(\.rawTransaction.networkFees)
                                    .filter { $0 != nil }
                                    .map {
                                        $0!.total.convertToBalance(
                                            decimals: $0!.token.decimals
                                        ).toString()
                                            + " "
                                            + $0!.token.symbol
                                    }
                                    .map {
                                        L10n
                                            .theFeeWasReservedSoYouWouldnTPayItAgainTheNextTimeYouCreatedATransactionOfTheSameType(
                                                $0
                                            )
                                    }
                                    .assign(to: \.text, on: label)
                                    .store(in: &subscriptions)
                            }
                    }
                    .padding(.init(top: 0, left: 18, bottom: 14, right: 18))
                    .setup { view in
                        viewModel.pendingTransactionPublisher
                            .map { $0.status.error != FeeRelayerError.topUpSuccessButTransactionThrows.message }
                            .assign(to: \.isHidden, on: view)
                            .store(in: &subscriptions)
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
                                        viewModel.pendingTransactionPublisher
                                            .map {
                                                $0.transactionId?
                                                    .truncatingMiddle(numOfSymbolsRevealed: 9,
                                                                      numOfSymbolsRevealedInSuffix: 9)
                                            }
                                            .assign(to: \.text, on: label)
                                            .store(in: &subscriptions)
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
                        viewModel.pendingTransactionPublisher
                            .map { $0.transactionId == nil }
                            .assign(to: \.isHidden, on: view)
                            .store(in: &subscriptions)
                    }

                    // Buttons
                    BEVStack(spacing: 10) {
                        WLStepButton.main(
                            image: .buttonCheckSmall,
                            text: L10n.done
                        ).onTap { [weak self] in
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
            viewModel.navigationPublisher
                .sink { [weak self] in self?.navigate(to: $0) }
                .store(in: &subscriptions)

            viewModel.pendingTransactionPublisher
                .map { $0.transactionId == nil }
                .sink { [weak self] _ in
                    UIView.animate(withDuration: 0.3) {
                        self?.updatePresentationLayout()
                    }
                }
                .store(in: &subscriptions)
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
