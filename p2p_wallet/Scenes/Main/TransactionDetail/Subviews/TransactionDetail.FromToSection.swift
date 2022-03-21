//
//  TransactionDetail.FromToSection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/03/2022.
//

import Foundation
import RxCocoa
import RxSwift
import UIKit

extension TransactionDetail {
    final class FromToSection: UIStackView {
        private let disposeBag = DisposeBag()
        private let viewModel: TransactionDetailViewModelType
        var isSwapDriver: Driver<Bool> {
            viewModel.parsedTransactionDriver
                .map { $0?.value is SolanaSDK.SwapTransaction }
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
                            isSwapDriver
                                .map { $0 ? L10n.from : L10n.senderSAddress }
                                .drive(fromTitleLabel.rx.text)
                                .disposed(by: disposeBag)
                        }

                    BEVStack(spacing: 8) {
                        addressLabel()
                            .setup { fromAddressLabel in
                                viewModel.parsedTransactionDriver
                                    .map { $0?.value }
                                    .map { transaction -> String? in
                                        switch transaction {
                                        case let transaction as SolanaSDK.SwapTransaction:
                                            return transaction.source?.pubkey
                                        case let transaction as SolanaSDK.TransferTransaction:
                                            return transaction.source?.pubkey
                                        default:
                                            return nil
                                        }
                                    }
                                    .drive(fromAddressLabel.rx.text)
                                    .disposed(by: disposeBag)
                            }
                        nameLabel()
                            .setup { fromNameLabel in
                                isSwapDriver
                                    .drive(fromNameLabel.rx.isHidden)
                                    .disposed(by: disposeBag)

                                viewModel.senderNameDriver
                                    .drive(fromNameLabel.rx.text)
                                    .disposed(by: disposeBag)
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
                            isSwapDriver
                                .map { $0 ? L10n.to : L10n.recipientSAddress }
                                .drive(toTitleLabel.rx.text)
                                .disposed(by: disposeBag)
                        }

                    BEVStack(spacing: 8) {
                        addressLabel()
                            .setup { toAddressLabel in
                                viewModel.parsedTransactionDriver
                                    .map { $0?.value }
                                    .map { transaction -> String? in
                                        switch transaction {
                                        case let transaction as SolanaSDK.SwapTransaction:
                                            return transaction.destination?.pubkey
                                        case let transaction as SolanaSDK.TransferTransaction:
                                            return transaction.destination?.pubkey
                                        default:
                                            return nil
                                        }
                                    }
                                    .drive(toAddressLabel.rx.text)
                                    .disposed(by: disposeBag)
                            }
                        nameLabel()
                            .setup { toNameLabel in
                                isSwapDriver
                                    .drive(toNameLabel.rx.isHidden)
                                    .disposed(by: disposeBag)

                                viewModel.receiverNameDriver
                                    .drive(toNameLabel.rx.text)
                                    .disposed(by: disposeBag)
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
