//
//  OrcaSwapV2.DetailsView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 03.12.2021.
//

import BEPureLayout
import Combine
import UIKit

extension OrcaSwapV2 {
    final class DetailsView: UIStackView {
        private lazy var ratesStack = RatesStackView(
            exchangeRatePublisher: viewModel.exchangeRatePublisher,
            sourceWalletPublisher: viewModel.sourceWalletPublisher,
            destinationWalletPublisher: viewModel.destinationWalletPublisher
        )
        private let slippageView = ClickableRow(title: L10n.maxPriceSlippage)
        private let payFeesWithView = ClickableRow(title: L10n.paySwapFeesWith)
        private lazy var feesView = DetailFeesView(viewModel: viewModel)

        private let viewModel: OrcaSwapV2ViewModelType
        private var subscriptions = [AnyCancellable]()

        init(viewModel: OrcaSwapV2ViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)

            layout()
            bind()
        }

        @available(*, unavailable)
        required init(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func layout() {
            axis = .vertical
            alignment = .fill

            slippageView.autoSetDimension(.height, toSize: 66)
            payFeesWithView.autoSetDimension(.height, toSize: 66)

            addArrangedSubviews {
                ratesStack
                BEStackViewSpacing(18)
                UIView.defaultSeparator()
                slippageView
                UIView.defaultSeparator()
                payFeesWithView
                UIView.defaultSeparator()
                BEStackViewSpacing(22)
                feesView
            }
        }

        private func bind() {
            viewModel.slippagePublisher
                .sink { [weak slippageView] in
                    slippageView?.setValue(text: "\($0 * 100)%")
                }
                .store(in: &subscriptions)

            viewModel.feePayingTokenStringPublisher
                .sink { [weak payFeesWithView] in
                    payFeesWithView?.setValue(text: $0)
                }
                .store(in: &subscriptions)

            slippageView.clickHandler = { [weak viewModel] in
                viewModel?.navigate(to: .settings)
            }

            payFeesWithView.clickHandler = { [weak viewModel] in
                viewModel?.choosePayFee()
            }

            feesView.clickHandler = { [weak viewModel] fee in
                guard let info = fee.info else { return }
                viewModel?.navigate(to: .info(title: info.alertTitle, description: info.alertDescription))
            }
        }
    }
}
