//
//  TransactionDetail.FromToSection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/03/2022.
//

import Combine
import Foundation
import SolanaSwift
import TransactionParser
import UIKit

extension TransactionDetail {
    final class FromToSection: UIStackView {
        private var subscriptions = [AnyCancellable]()
        private let viewModel: TransactionDetailViewModelType
        var isSwapPublisher: AnyPublisher<Bool, Never> {
            viewModel.parsedTransactionPublisher
                .map { $0?.info is SwapInfo }
                .eraseToAnyPublisher()
        }

        init(viewModel: TransactionDetailViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
            set(axis: .vertical, spacing: 18, alignment: .fill, distribution: .fill)
            addArrangedSubviews {
                // Separator
                UIView.defaultSeparator()

                // Sender
                BEHStack(spacing: 12, alignment: .top) {
                    titleLabel()
                        .setup { fromTitleLabel in
                            isSwapPublisher
                                .map { $0 ? L10n.from : L10n.senderSAddress }
                                .assign(to: \.text, on: fromTitleLabel)
                                .store(in: &subscriptions)
                        }

                    BEVStack(spacing: 8) {
                        addressLabel()
                            .setup { fromAddressLabel in
                                viewModel.parsedTransactionPublisher
                                    .map { $0?.info }
                                    .map { transaction -> String? in
                                        switch transaction {
                                        case let transaction as SwapInfo:
                                            return transaction.source?.pubkey
                                        case let transaction as TransferInfo:
                                            return transaction.source?.pubkey
                                        default:
                                            return nil
                                        }
                                    }
                                    .assign(to: \.text, on: fromAddressLabel)
                                    .store(in: &subscriptions)
                            }
                        nameLabel()
                            .setup { fromNameLabel in
                                isSwapPublisher
                                    .assign(to: \.isHidden, on: fromNameLabel)
                                    .store(in: &subscriptions)

                                viewModel.senderNamePublisher
                                    .assign(to: \.text, on: fromNameLabel)
                                    .store(in: &subscriptions)
                            }
                    }
                    .onLongTap { [unowned self] gesture in
                        guard gesture.state == .ended else { return }
                        self.viewModel.copySourceAddressToClipboard()
                    }
                }

                // Separator
                UIView.defaultSeparator()

                // Recipient
                BEHStack(spacing: 12, alignment: .top) {
                    titleLabel()
                        .setup { toTitleLabel in
                            isSwapPublisher
                                .map { $0 ? L10n.to : L10n.recipientSAddress }
                                .assign(to: \.text, on: toTitleLabel)
                                .store(in: &subscriptions)
                        }

                    BEVStack(spacing: 8) {
                        addressLabel()
                            .setup { toAddressLabel in
                                viewModel.parsedTransactionPublisher
                                    .map { $0?.info }
                                    .map { transaction -> String? in
                                        switch transaction {
                                        case let transaction as SwapInfo:
                                            return transaction.destination?.pubkey
                                        case let transaction as TransferInfo:
                                            return transaction.destination?.pubkey
                                        default:
                                            return nil
                                        }
                                    }
                                    .assign(to: \.text, on: toAddressLabel)
                                    .store(in: &subscriptions)
                            }
                        nameLabel()
                            .setup { toNameLabel in
                                isSwapPublisher
                                    .assign(to: \.isHidden, on: toNameLabel)
                                    .store(in: &subscriptions)

                                viewModel.receiverNamePublisher
                                    .assign(to: \.text, on: toNameLabel)
                                    .store(in: &subscriptions)
                            }
                    }
                    .onLongTap { [unowned self] gesture in
                        guard gesture.state == .ended else { return }
                        self.viewModel.copyDestinationAddressToClipboard()
                    }
                }
            }
        }

        @available(*, unavailable)
        required init(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

private func titleLabel() -> UILabel {
    UILabel(text: "Sender’s address", textSize: 15, textColor: .textSecondary, numberOfLines: 2)
        .withContentHuggingPriority(.required, for: .horizontal)
}

private func addressLabel() -> UILabel {
    UILabel(text: "FfRBgsYFtBW7Vo5hRetqEbdxrwU8KNRn1ma6sBTBeJEr", textSize: 15, numberOfLines: 2, textAlignment: .right)
}

private func nameLabel() -> UILabel {
    UILabel(text: "name.p2p.sol", textSize: 15, textColor: .textSecondary, textAlignment: .right)
}
