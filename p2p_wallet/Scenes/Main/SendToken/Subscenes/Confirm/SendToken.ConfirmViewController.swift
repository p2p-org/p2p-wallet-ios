//
//  SendToken.ConfirmViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 02/12/2021.
//

import AnalyticsManager
import BEPureLayout
import Combine
import Foundation
import Resolver
import UIKit

extension SendToken {
    final class ConfirmViewController: BaseVC {
        // MARK: - Dependencies

        @Injected private var analyticsManager: AnalyticsManager

        private let viewModel: SendTokenViewModelType
        private var subscriptions = [AnyCancellable]()

        // MARK: - Subviews

        private lazy var alertBannerView = UIView.greyBannerView(axis: .horizontal, spacing: 18, alignment: .top) {
            UILabel(
                text: L10n.BeSureAllDetailsAreCorrectBeforeConfirmingTheTransaction.onceConfirmedItCannotBeReversed,
                textSize: 15,
                numberOfLines: 0
            )
            UIView.closeBannerButton()
                .onTap(self, action: #selector(closeBannerButtonDidTouch))
        }

        // MARK: - Initializer

        init(viewModel: SendTokenViewModelType) {
            self.viewModel = viewModel
            super.init()
            analyticsManager.log(event: AmplitudeEvent.sendApprovedScreen)
        }

        override func setUp() {
            super.setUp()

            // layout
            let stackView = UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill) {
                // Alert banner
                if viewModel.shouldShowConfirmAlert() {
                    alertBannerView
                }

                // Amount
                UIView.floatingPanel {
                    AmountSummaryView()
                        .setup { view in
                            view.addArrangedSubview(.defaultNextArrow())
                            Publishers.CombineLatest(
                                viewModel.walletPublisher,
                                viewModel.amountPublisher
                            )
                                .sink { [weak view] param in
                                    view?.setUp(wallet: param.0, amount: param.1 ?? 0)
                                }
                                .store(in: &subscriptions)
                        }
                }
                .onTap { [weak self] in
                    self?.viewModel.navigate(to: .chooseTokenAndAmount(showAfterConfirmation: true))
                }

                // Recipient
                UIView.floatingPanel {
                    RecipientView()
                        .setup { view in
                            view.addArrangedSubview(.defaultNextArrow())
                            viewModel.recipientPublisher
                                .sink { [weak view] recipient in
                                    view?.setUp(recipient: recipient)
                                }
                                .store(in: &subscriptions)
                        }
                }
                .onTap { [weak self] in
                    self?.viewModel
                        .navigate(to: .chooseRecipientAndNetwork(
                            showAfterConfirmation: true,
                            preSelectedNetwork: nil,
                            maxWasClicked: false
                        ))
                }

                // Network
                UIView.floatingPanel {
                    NetworkView()
                        .setup { view in
                            view.addArrangedSubview(.defaultNextArrow())
                            Publishers.CombineLatest3(
                                viewModel.networkPublisher,
                                viewModel.payingWalletPublisher,
                                viewModel.feeInfoPublisher
                            )
                                .receive(on: RunLoop.main)
                                .sink { [weak self, weak view] network, payingWallet, feeInfo in
                                    guard let self = self else { return }
                                    view?.setUp(
                                        network: network,
                                        payingWallet: payingWallet,
                                        feeInfo: feeInfo.value,
                                        prices: self.viewModel.getPrices(for: ["SOL", "renBTC"])
                                    )
                                }
                                .store(in: &subscriptions)
                        }
                }
                .onTap { [weak self] in
                    self?.viewModel.navigate(to: .chooseNetwork)
                }

                // Paying fee token
                if viewModel.relayMethod == .relay {
                    FeeView(
                        solPrice: viewModel.getPrice(for: "SOL"),
                        payingWalletPublisher: viewModel.payingWalletPublisher,
                        feeInfoPublisher: viewModel.feeInfoPublisher
                    )
                        .setup { view in
                            Publishers.CombineLatest(
                                viewModel.networkPublisher,
                                viewModel.feeInfoPublisher
                            )
                                .map { network, fee in
                                    if network != .solana { return true }
                                    if let fee = fee.value?.feeAmount {
                                        return fee.total == 0
                                    } else {
                                        return true
                                    }
                                }
                                .assign(to: \.isHidden, on: view)
                                .store(in: &subscriptions)
                        }
                        .onTap { [weak self] in
                            self?.viewModel
                                .navigate(to: .chooseRecipientAndNetwork(
                                    showAfterConfirmation: true,
                                    preSelectedNetwork: nil,
                                    maxWasClicked: false
                                ))
                        }
                }

                BEStackViewSpacing(18)

                // Fee sections
                UIStackView(axis: .vertical, spacing: 12, alignment: .fill, distribution: .fill) {
                    // Receive
                    SectionView(title: L10n.receive)
                        .setup { view in
                            Publishers.CombineLatest(
                                viewModel.walletPublisher,
                                viewModel.amountPublisher
                            )
                                .map { wallet, amount in
                                    let amount = amount
                                    let amountInFiat = amount * wallet?.priceInCurrentFiat.orZero

                                    return NSMutableAttributedString()
                                        .text(
                                            "\(amount.toString(maximumFractionDigits: 9)) \(wallet?.token.symbol ?? "") ",
                                            size: 15,
                                            color: .textBlack
                                        )
                                        .text(
                                            "(~\(Defaults.fiat.symbol)\(amountInFiat.toString(maximumFractionDigits: 2)))",
                                            size: 15,
                                            color: .textSecondary
                                        )
                                }
                                .assign(to: \.attributedText, on: view.rightLabel)
                                .store(in: &subscriptions)
                        }

                    // Fees
                    FeesView(viewModel: viewModel) { [weak self] title, message in
                        self?.showAlert(
                            title: title,
                            message: message,
                            buttonTitles: [L10n.ok],
                            highlightedButtonIndex: 0,
                            completion: nil
                        )
                    }
                }

                BEStackViewSpacing(18)

                UIView.defaultSeparator()

                // Prices
                UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill) {
                    SectionView(title: "<1 USD>")
                        .setup { view in
                            view.leftLabel.text = "1 \(Defaults.fiat.code)"
                            viewModel.walletPublisher
                                .map { [weak self] in
                                    (self?.viewModel.getPrice(for: $0?.token.symbol ?? ""),
                                     $0?.token.symbol ?? "")
                                }
                                .map { price, symbol in
                                    let price: Double = price == 0 ? 0 : 1 / price
                                    return price.toString(maximumFractionDigits: 9) + " " + symbol
                                }
                                .assign(to: \.text, on: view.rightLabel)
                                .store(in: &subscriptions)
                        }

                    SectionView(title: "<1 renBTC>")
                        .setup { view in
                            viewModel.walletPublisher
                                .map { $0?.token.symbol ?? "" }
                                .map { "1 \($0)" }
                                .assign(to: \.text, on: view.leftLabel)
                                .store(in: &subscriptions)

                            viewModel.walletPublisher
                                .map { [weak self] in
                                    (self?.viewModel.getPrice(for: $0?.token.symbol ?? ""),
                                     $0?.token.symbol ?? "")
                                }
                                .map { price, _ in
                                    price?.toString(maximumFractionDigits: 2) + " " + Defaults.fiat.code
                                }
                                .assign(to: \.text, on: view.rightLabel)
                                .store(in: &subscriptions)
                        }
                }
            }

            let scrollView = ContentHuggingScrollView(
                scrollableAxis: .vertical,
                contentInset: .init(top: 8, left: 18, bottom: 18, right: 18)
            )
            scrollView.contentView.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges()

            view.addSubview(scrollView)
            scrollView.autoPinEdge(toSuperviewEdge: .top, withInset: 8)
            scrollView.autoPinEdge(toSuperviewEdge: .leading)
            scrollView.autoPinEdge(toSuperviewEdge: .trailing)

            let actionButton = WLStepButton.main(image: .buttonSendSmall, text: L10n.sendNow)
                .setup { view in
                    Publishers.CombineLatest(
                        viewModel.walletPublisher,
                        viewModel.amountPublisher
                    )
                        .map { wallet, amount in
                            let amount = amount ?? 0
                            let symbol = wallet?.token.symbol ?? ""
                            return L10n.send(amount.toString(maximumFractionDigits: 9), symbol)
                        }
                        .receive(on: RunLoop.main)
                        .sink { [weak view] in view?.text = $0 }
                        .store(in: &subscriptions)

                    Publishers.CombineLatest3(
                        viewModel.walletPublisher.map { $0 != nil },
                        viewModel.amountPublisher.map { $0 != nil },
                        viewModel.recipientPublisher.map { $0 != nil }
                    )
                        .map { $0 && $1 && $2 }
                        .assign(to: \.isEnabled, on: view)
                        .store(in: &subscriptions)
                }
                .onTap { [weak self] in
                    self?.viewModel.authenticateAndSend()
                }

            view.addSubview(actionButton)
            actionButton.autoPinEdge(.top, to: .bottom, of: scrollView, withOffset: 8)
            actionButton.autoPinEdgesToSuperviewSafeArea(with: .init(all: 18), excludingEdge: .top)

            Publishers.CombineLatest(
                viewModel.feeInfoPublisher.map { $0.value?.feeAmount },
                viewModel.payingWalletPublisher
            )
                .sink { [weak stackView, weak view] _ in
                    stackView?.setNeedsLayout()
                    view?.layoutIfNeeded()
                }
                .store(in: &subscriptions)
        }

        override func bind() {
            super.bind()
            // title
            viewModel.walletPublisher
                .map { L10n.confirmSending($0?.token.symbol ?? "") }
                .sink { [weak self] in
                    self?.navigationItem.title = $0
                }
                .store(in: &subscriptions)
        }

        // MARK: - Actions

        @objc private func closeBannerButtonDidTouch() {
            viewModel.closeConfirmAlert()
            UIView.animate(withDuration: 0.3) {
                self.alertBannerView.isHidden = true
            }
        }
    }
}
