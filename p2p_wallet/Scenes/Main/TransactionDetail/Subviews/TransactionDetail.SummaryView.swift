//
//  TransactionDetail.SummaryView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/03/2022.
//

import BEPureLayout
import Combine
import Foundation
import SolanaSwift
import TransactionParser
import UIKit

extension TransactionDetail {
    final class SummaryView: UIStackView {
        private var subscriptions = [AnyCancellable]()
        private let viewModel: TransactionDetailViewModelType

        init(viewModel: TransactionDetailViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
            set(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill)

            let leftView = SubView()
                .setup { view in
                    viewModel.parsedTransactionDriver
                        .sink { [weak view] parsedTransaction in
                            switch parsedTransaction?.info {
                            case let transaction as TransferInfo:
                                view?.logoImageView.setUp(wallet: transaction.source)
                                view?.titleLabel.text = transaction.rawAmount?
                                    .toString(maximumFractionDigits: 9) + " " + transaction.source?.token.symbol
                                view?.subtitleLabel.text = "~ " + Defaults.fiat.symbol + viewModel
                                    .getAmountInCurrentFiat(
                                        amountInToken: transaction.rawAmount,
                                        symbol: transaction.source?.token.symbol
                                    ).toString(maximumFractionDigits: 2)
                            case let transaction as SwapInfo:
                                view?.logoImageView.setUp(wallet: transaction.source)
                                view?.titleLabel.text = transaction.sourceAmount?
                                    .toString(maximumFractionDigits: 9) + " " + transaction.source?.token.symbol
                                view?.subtitleLabel.text = "~ " + Defaults.fiat.symbol + viewModel
                                    .getAmountInCurrentFiat(
                                        amountInToken: transaction.sourceAmount,
                                        symbol: transaction.source?.token.symbol
                                    ).toString(maximumFractionDigits: 2)
                            default:
                                break
                            }
                        }
                        .store(in: &subscriptions)
                }
            let rightView = SubView()
                .setup { view in
                    Publishers.CombineLatest(
                        viewModel.parsedTransactionDriver,
                        viewModel.receiverNameDriver
                    )
                        .sink { [weak view] parsedTransaction, receiverName in
                            switch parsedTransaction?.info {
                            case let transaction as TransferInfo:
                                view?.logoImageView.setUp(token: nil, placeholder: .squircleWallet)
                                view?.titleLabel.text = transaction.destination?.pubkey?.truncatingMiddle()
                                view?.subtitleLabel.text = receiverName ?? " "
                            case let transaction as SwapInfo:
                                view?.logoImageView.setUp(wallet: transaction.destination)
                                view?.titleLabel.text = transaction.destinationAmount?
                                    .toString(maximumFractionDigits: 9) + " " + transaction.destination?.token.symbol
                                view?.subtitleLabel.text = "~ " + Defaults.fiat.symbol +
                                    viewModel.getAmountInCurrentFiat(
                                        amountInToken: transaction.destinationAmount,
                                        symbol: transaction.destination?.token.symbol
                                    )
                                    .toString(maximumFractionDigits: 2)
                            default:
                                break
                            }
                        }
                        .store(in: &subscriptions)
                }

            addArrangedSubviews {
                leftView
                UIImageView(width: 32, height: 32, image: .squircleArrowForward, tintColor: .textSecondary)
                rightView
            }

            leftView.widthAnchor.constraint(equalTo: rightView.widthAnchor).isActive = true
        }

        @available(*, unavailable)
        required init(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

private extension TransactionDetail.SummaryView {
    final class SubView: UIStackView {
        fileprivate let logoImageView = CoinLogoImageView(size: 44)
        fileprivate let titleLabel = UILabel(
            text: "0.00227631 renBTC",
            textSize: 15,
            numberOfLines: 0,
            textAlignment: .center
        )
        fileprivate let subtitleLabel = UILabel(
            text: "~ $150",
            textSize: 13,
            textColor: .textSecondary,
            numberOfLines: 0,
            textAlignment: .center
        )

        init() {
            super.init(frame: .zero)
            set(axis: .vertical, spacing: 8, alignment: .center, distribution: .fill)
            addArrangedSubviews {
                logoImageView
                titleLabel
                BEStackViewSpacing(0)
                subtitleLabel
            }
        }

        @available(*, unavailable)
        required init(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
