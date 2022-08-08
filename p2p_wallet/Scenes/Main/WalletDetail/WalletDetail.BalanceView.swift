//
//  WalletDetail.BalanceView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 18.01.2022.
//

import Combine
import UIKit

extension WalletDetail {
    final class BalanceView: UIStackView {
        private let tokenBalanceTitle = UILabel(textSize: 28, weight: .bold, textAlignment: .center)
        private let fiatBalanceTitle = UILabel(
            textSize: 13,
            weight: .medium,
            textColor: .h8e8e93,
            textAlignment: .center
        )

        private let viewModel: WalletDetailViewModelType
        private var subscriptions = [AnyCancellable]()

        init(viewModel: WalletDetailViewModelType) {
            self.viewModel = viewModel

            super.init(frame: .zero)

            bind()
            axis = .vertical
            spacing = 4
            addArrangedSubviews([tokenBalanceTitle, fiatBalanceTitle])
        }

        @available(*, unavailable)
        required init(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func bind() {
            viewModel.walletPublisher.map {
                "\($0?.amount.toString(maximumFractionDigits: 9) ?? "") \($0?.token.symbol ?? "")"
            }
            .assign(to: \.text, on: tokenBalanceTitle)
            .store(in: &subscriptions)

            // equityValue label
            viewModel.walletPublisher.map {
                $0?.amountInCurrentFiat
                    .toString(maximumFractionDigits: 2)
            }
            .map { Defaults.fiat.symbol + " " + ($0 ?? "0") }
            .assign(to: \.text, on: fiatBalanceTitle)
            .store(in: &subscriptions)
        }
    }
}
