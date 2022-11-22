//
//  ReceiveToken.ReceiveBitcoinView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import Foundation
import UIKit
import Combine

extension ReceiveToken {
    class ReceiveBitcoinView: BECompositionView {
        private var subscriptions = [AnyCancellable]()
        private let viewModel: ReceiveBitcoinViewModel

        // MARK: - Initializers

        init(viewModel: ReceiveBitcoinViewModel) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }

        override func build() -> UIView {
            UIStackView(axis: .vertical, spacing: 18, alignment: .fill) {
                // Qr code
                QrCodeCard(token: .renBTC)
                    .onCopy { [unowned self] _ in
                        self.viewModel.copyToClipboard()
                    }.onShare { [unowned self] image in
                        self.viewModel.share(image: image)
                    }.onSave { [unowned self] image in
                        self.viewModel.saveAction(image: image)
                    }.setup { card in
                        viewModel.gatewayAddressPublisher
                            .assign(to: \.pubKey, on: card)
                            .store(in: &subscriptions)
                    }

                // Status
                statusButton()

                // Description
                UIView.greyBannerView(spacing: 12) {
                    ReceiveToken
                        .textBuilder(text: L10n.ThisAddressAcceptsOnly
                            .youMayLoseAssetsBySendingAnotherCoin(L10n.bitcoin).asMarkdown())
                    ReceiveToken.textBuilder(text: L10n.minimumTransactionAmountOf("0.000112 BTC").asMarkdown()
                    )
                        .setup { view in
                            guard let label = view.viewWithTag(1) as? UILabel else {return}
                            viewModel.minimumTransactionAmountPublisher
                                .map {
                                    L10n.minimumTransactionAmountOf(
                                        $0.toString(maximumFractionDigits: 6)
                                    )
                                    .asMarkdown()
                                }
                                .assign(to: \.attributedText, on: label)
                                .store(in: &subscriptions)
                        }
                    ReceiveToken
                        .textBuilder(text: L10n.isTheRemainingTimeToSafelySendTheAssets("35:59:59").asMarkdown())
                        .setup { view in
                            guard let textLabel = view.viewWithTag(1) as? UILabel else { return }
                            viewModel.timeRemainsPublisher
                                .assign(to: \.attributedText, on: textLabel)
                                .store(in: &subscriptions)
                        }
                }
                if viewModel.hasExplorerButton {
                    ExplorerButton(title: L10n.viewInExplorer(L10n.bitcoin))
                        .onTap { [weak self] in self?.viewModel.showBTCAddressInExplorer() }
                }
            }
            .setup { view in
                viewModel.statePublisher
                    .sink { [weak self] state in
                        self?.hideLoadingIndicatorView()
                        self?.removeErrorView()
                        switch state {
                        case .initializing, .loading:
                            self?.hideConnectionErrorView()
                            self?.showLoadingIndicatorView(isBlocking: true)
                        case .error:
                            self?.showErrorView { [weak self] in
                                self?.viewModel.acceptConditionAndLoadAddress()
                            }
                        default:
                            break
                        }
                    }
                    .store(in: &subscriptions)
            }
        }

        func statusButton() -> UIView {
            WLCard {
                UIStackView(axis: .horizontal) {
                    UIImageView(image: .receiveSquircle)
                        .frame(width: 44, height: 44)
                        .padding(.init(only: .right, inset: 12))
                    UIStackView(axis: .vertical, alignment: .fill) {
                        // Title
                        UILabel(text: L10n.statusesReceived, textSize: 17)
                        // Last time
                        UILabel(text: "\(L10n.theLastOne) 0m ago", textSize: 13, textColor: .secondaryLabel)
                            .setup { view in
                                viewModel.lastTrxDatePublisher
                                    .assign(to: \.text, on: view)
                                    .store(in: &subscriptions)
                            }
                    }
                    UIView.spacer
                    UILabel(text: "0")
                        .setup { view in
                            viewModel.txsCountPublisher
                                .assign(to: \.text, on: view)
                                .store(in: &subscriptions)
                        }
                        .padding(.init(only: .right, inset: 8))
                    // Arrow
                    UIView.defaultNextArrow()
                        .setup { view in
                            viewModel.processingTransactionsPublisher
                                .map(\.isEmpty)
                                .assign(to: \.isHidden, on: view)
                                .store(in: &subscriptions)
                        }
                }.padding(.init(x: 18, y: 14))
            }
            .setup { view in
                viewModel.showReceivingStatusesEnablePublisher
                    .assign(to: \.isUserInteractionEnabled, on: view)
                    .store(in: &subscriptions)
            }
            .onTap { [unowned self] in viewModel.showReceivingStatuses() }
        }
    }
}

private extension ReceiveToken.ReceiveBitcoinViewModel {
    var showReceivingStatusesEnablePublisher: AnyPublisher<Bool, Never> {
        processingTransactionsPublisher
            .map { !$0.isEmpty }
            .eraseToAnyPublisher()
    }

    var txsCountPublisher: AnyPublisher<String?, Never> {
        processingTransactionsPublisher
            .map { trx in "\(trx.count)" }
            .eraseToAnyPublisher()
    }

    var lastTrxDatePublisher: AnyPublisher<String?, Never> {
        processingTransactionsPublisher
            .map { trx in
                guard let receiveAt = trx.first?.timestamp.firstReceivedAt else
                { return L10n.none }

                // Time formatter
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .short
                let time = formatter.localizedString(for: receiveAt, relativeTo: Date())

                return "\(L10n.theLastOne) \(time)"
            }
            .eraseToAnyPublisher()
    }

    var timeRemainsPublisher: AnyPublisher<NSAttributedString?, Never> {
        timerPublisher.map { [weak self] _ in
            guard let self = self else { return L10n.isTheRemainingTimeToSafelySendTheAssets("35:59:59").asMarkdown() }
            guard let endAt = self.sessionEndDate
            else { return L10n.isTheRemainingTimeToSafelySendTheAssets("35:59:59").asMarkdown() }
            let currentDate = Date()
            let calendar = Calendar.current

            let d = calendar.dateComponents([.hour, .minute, .second], from: currentDate, to: endAt)
            let countdown = String(format: "%02d:%02d:%02d", d.hour ?? 0, d.minute ?? 0, d.second ?? 0)

            return L10n.isTheRemainingTimeToSafelySendTheAssets(countdown).asMarkdown()
        }
        .eraseToAnyPublisher()
    }
}
