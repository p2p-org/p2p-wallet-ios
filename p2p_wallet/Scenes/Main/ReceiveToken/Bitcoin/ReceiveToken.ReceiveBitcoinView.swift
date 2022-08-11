//
//  ReceiveToken.ReceiveBitcoinView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import Combine
import Foundation
import UIKit

extension ReceiveToken {
    class ReceiveBitcoinView: BECompositionView {
        private var subscriptions = [AnyCancellable]()
        private let viewModel: ReceiveTokenBitcoinViewModelType

        // MARK: - Initializers

        init(viewModel: ReceiveTokenBitcoinViewModelType) {
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
                        viewModel.addressPublisher
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
                    ReceiveToken.textBuilder(text: L10n.minimumTransactionAmountOf("0.000112 BTC").asMarkdown())
                    ReceiveToken
                        .textBuilder(text: L10n.isTheRemainingTimeToSafelySendTheAssets("35:59:59").asMarkdown())
                        .setup { view in
                            guard let textLabel = view.viewWithTag(1) as? UILabel else { return }
                            viewModel.timeRemainsPublisher()
                                .assign(to: \.attributedText, on: textLabel)
                                .store(in: &subscriptions)
                        }
                }
                if viewModel.hasExplorerButton {
                    ExplorerButton(title: L10n.viewInExplorer(L10n.bitcoin))
                        .onTap { [weak self] in self?.viewModel.showBTCAddressInExplorer() }
                }
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
                                viewModel.lastTrxDate().assign(to: \.text, on: view).store(in: &subscriptions)
                            }
                    }
                    UIView.spacer
                    UILabel(text: "0")
                        .setup { view in
                            viewModel.txsCountPublisher().assign(to: \.text, on: view).store(in: &subscriptions)
                        }
                        .padding(.init(only: .right, inset: 8))
                    // Arrow
                    UIView.defaultNextArrow()
                        .setup { view in
                            viewModel.processingTxsPublisher
                                .map(\.isEmpty)
                                .assign(to: \.isHidden, on: view)
                                .store(in: &subscriptions)
                        }
                }.padding(.init(x: 18, y: 14))
            }
            .setup { view in
                viewModel.showReceivingStatusesEnablePublisher()
                    .assign(to: \.isUserInteractionEnabled, on: view)
                    .store(in: &subscriptions)
            }
            .onTap { [unowned self] in viewModel.showReceivingStatuses() }
        }
    }
}

private extension ReceiveTokenBitcoinViewModelType {
    func showReceivingStatusesEnablePublisher() -> AnyPublisher<Bool, Never> {
        processingTxsPublisher
            .map { !$0.isEmpty }
            .eraseToAnyPublisher()
    }

    func txsCountPublisher() -> AnyPublisher<String?, Never> {
        processingTxsPublisher
            .map { trx in "\(trx.count)" }
            .eraseToAnyPublisher()
    }

    func lastTrxDate() -> AnyPublisher<String?, Never> {
        processingTxsPublisher
            .map { trx in
                guard let lastTrx = trx.first,
                      let receiveAt = lastTrx.submitedAt else { return L10n.none }

                // Time formatter
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .short
                let time = formatter.localizedString(for: receiveAt, relativeTo: Date())

                return "\(L10n.theLastOne) \(time)"
            }
            .eraseToAnyPublisher()
    }

    func timeRemainsPublisher() -> AnyPublisher<NSAttributedString?, Never> {
        timerPublisher.map { [weak self] in
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
