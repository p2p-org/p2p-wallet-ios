//
//  OrcaSwapV2.ConfirmSwapping.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2021.
//

import BEPureLayout
import Combine
import Foundation
import UIKit

extension OrcaSwapV2.ConfirmSwapping {
    final class RootView: ScrollableVStackRootView {
        // MARK: - Properties

        private let viewModel: OrcaSwapV2ConfirmSwappingViewModelType
        private var subscriptions = [AnyCancellable]()

        // MARK: - Subviews

        private lazy var bannerView = UIView.greyBannerView(axis: .horizontal, spacing: 12, alignment: .top) {
            UILabel(
                text: L10n.BeSureAllDetailsAreCorrectBeforeConfirmingTheTransaction
                    .onceConfirmedItCannotBeReversed,
                textSize: 15,
                numberOfLines: 0
            )
            UIView.closeBannerButton()
                .onTap(self, action: #selector(closeBannerButtonDidTouch))
        }

        private lazy var inputAmountLabel = UILabel(text: nil, textSize: 15, numberOfLines: 0, textAlignment: .right)
            .withContentHuggingPriority(.required, for: .horizontal)
        private lazy var minimumAmountLabel = UILabel(text: nil, textSize: 15, numberOfLines: 0, textAlignment: .right)
            .withContentHuggingPriority(.required, for: .horizontal)
        private lazy var slippageLabel = UILabel(text: nil, textSize: 15, textAlignment: .right)
        private lazy var ratesView = OrcaSwapV2.RatesStackView(
            exchangeRatePublisher: viewModel.exchangeRatesPublisher,
            sourceWalletPublisher: viewModel.sourceWalletPublisher,
            destinationWalletPublisher: viewModel.destinationWalletPublisher
        )
        private lazy var feesView = OrcaSwapV2.DetailFeesView(viewModel: viewModel)
        private lazy var actionButton = WLStepButton.main(image: .buttonSwapSmall, text: nil)
            .onTap(self, action: #selector(actionButtonDidTouch))

        // MARK: - Initializers

        init(viewModel: OrcaSwapV2ConfirmSwappingViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
            scrollView.contentInset = .init(top: 8, left: 18, bottom: 18, right: 18)
            setUp()
            bind()
        }

        private func setUp() {
            stackView.spacing = 12
            stackView.addArrangedSubviews {
                UIView.floatingPanel(
                    contentInset: .init(x: 8, y: 16),
                    axis: .horizontal,
                    spacing: 8,
                    alignment: .center,
                    distribution: .equalCentering
                ) {
                    WalletView(viewModel: viewModel, type: .source)
                        .centered(.horizontal)

                    UIImageView(width: 11.88, height: 9.74, image: .arrowForward, tintColor: .h8e8e93)
                        .withContentHuggingPriority(.required, for: .horizontal)
                        .padding(.init(all: 10), backgroundColor: .fafafc, cornerRadius: 12)
                        .withContentHuggingPriority(.required, for: .horizontal)

                    WalletView(viewModel: viewModel, type: .destination)
                        .centered(.horizontal)
                }
                BEStackViewSpacing(26)

                createRow(title: L10n.spend, label: inputAmountLabel)
                createRow(title: L10n.receiveAtLeast, label: minimumAmountLabel)
                createRow(title: L10n.maxPriceSlippage, label: slippageLabel)

                BEStackViewSpacing(18)

                UIView.defaultSeparator()
                BEStackViewSpacing(18)
                ratesView
                BEStackViewSpacing(18)

                UIView.defaultSeparator()
                BEStackViewSpacing(18)
                feesView
            }

            if !viewModel.isBannerForceClosed() {
                stackView.insertArrangedSubview(bannerView, at: 0)
            }

            addSubview(actionButton)
            actionButton.autoPinEdge(.leading, to: .leading, of: self, withOffset: 18)
            actionButton.autoPinEdge(.trailing, to: .trailing, of: self, withOffset: -18)
            actionButton.autoPinEdge(toSuperviewSafeArea: .bottom, withInset: 18)

            scrollViewBottomConstraint.isActive = false
            actionButton.autoPinEdge(.top, to: .bottom, of: scrollView, withOffset: 18)
        }

        private func bind() {
            combinedAmountPublisher(
                amountPublisher: viewModel.inputAmountStringPublisher,
                amountInFiatPublisher: viewModel.inputAmountInFiatStringPublisher
            )
                .map(Optional.init)
                .assign(to: \.attributedText, on: inputAmountLabel)
                .store(in: &subscriptions)

            combinedAmountPublisher(
                amountPublisher: viewModel.receiveAtLeastStringPublisher,
                amountInFiatPublisher: viewModel.receiveAtLeastInFiatStringPublisher
            )
                .map(Optional.init)
                .assign(to: \.attributedText, on: minimumAmountLabel)
                .store(in: &subscriptions)

            viewModel.slippagePublisher
                .map { ($0 * 100).toString(maximumFractionDigits: 2) + "%" }
                .assign(to: \.text, on: slippageLabel)
                .store(in: &subscriptions)

            Publishers.CombineLatest(
                viewModel.sourceWalletPublisher.map { $0?.token.symbol },
                viewModel.destinationWalletPublisher.map { $0?.token.symbol }
            )
                .map { L10n.swap($0.0 ?? "", $0.1 ?? "") }
                .sink { [weak actionButton] in actionButton?.text = $0 }
                .store(in: &subscriptions)

            feesView.clickHandler = { [weak self] fee in
                guard let info = fee.info else { return }
                self?.viewModel.showFeesInfo(info)
            }
        }

        // MARK: - Action

        @objc private func closeBannerButtonDidTouch() {
            UIView.animate(withDuration: 0.3) {
                self.bannerView.isHidden = true
            }
            viewModel.closeBanner()
        }

        @objc private func actionButtonDidTouch() {
            viewModel.authenticateAndSwap()
        }

        // MARK: - Helpers

        private func createRow(title: String, label: UILabel) -> UIStackView {
            .init(axis: .horizontal, spacing: 8, alignment: .fill, distribution: .fill) {
                UILabel(text: title, textSize: 15, textColor: .textSecondary, numberOfLines: 0)
                label
            }
        }

        private func combinedAmountPublisher(
            amountPublisher: AnyPublisher<String?, Never>,
            amountInFiatPublisher: AnyPublisher<String?, Never>
        ) -> AnyPublisher<NSAttributedString, Never> {
            Publishers.CombineLatest(
                amountPublisher,
                amountInFiatPublisher
            )
                .map {
                    NSMutableAttributedString()
                        .text($0.0 ?? "0", size: 15)
                        .text(" (~" + ($0.1 ?? "") + ")", size: 15, color: .textSecondary)
                }
                .eraseToAnyPublisher()
        }
    }
}

extension OrcaSwapV2.ConfirmSwapping {
    private final class WalletView: UIStackView {
        enum WalletType {
            case source, destination
        }

        // MARK: - Properties

        private let viewModel: OrcaSwapV2ConfirmSwappingViewModelType
        private let type: WalletType
        private var subscriptions = [AnyCancellable]()

        // MARK: - Subviews

        private lazy var coinLogoImageView = CoinLogoImageView(size: 44, cornerRadius: 12)
        private lazy var amountLabel = UILabel(text: nil, textSize: 15, textAlignment: .center)
        private lazy var equityAmountLabel = UILabel(
            text: nil,
            textSize: 13,
            textColor: .textSecondary,
            textAlignment: .center
        )

        // MARK: - Initializers

        init(viewModel: OrcaSwapV2ConfirmSwappingViewModelType, type: WalletType) {
            self.viewModel = viewModel
            self.type = type
            super.init(frame: .zero)
            set(axis: .vertical, spacing: 0, alignment: .center, distribution: .fill)
            layout()
            bind()
        }

        @available(*, unavailable)
        required init(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Methods

        private func layout() {
            addArrangedSubviews {
                coinLogoImageView
                BEStackViewSpacing(12)
                amountLabel
                BEStackViewSpacing(3)
                equityAmountLabel
            }
        }

        private func bind() {
            let walletPublisher = type == .source ? viewModel.sourceWalletPublisher : viewModel
                .destinationWalletPublisher

            walletPublisher
                .sink { [weak coinLogoImageView] in coinLogoImageView?.wallet = $0 }
                .store(in: &subscriptions)

            switch type {
            case .source:
                viewModel.inputAmountStringPublisher
                    .assign(to: \.text, on: amountLabel)
                    .store(in: &subscriptions)

                viewModel.inputAmountInFiatStringPublisher
                    .map { "~ " + $0 }
                    .assign(to: \.text, on: equityAmountLabel)
                    .store(in: &subscriptions)
            case .destination:
                viewModel.estimatedAmountStringPublisher
                    .assign(to: \.text, on: amountLabel)
                    .store(in: &subscriptions)

                viewModel.receiveAtLeastStringPublisher
                    .map { "≥ " + $0 }
                    .assign(to: \.text, on: equityAmountLabel)
                    .store(in: &subscriptions)
            }
        }
    }
}
