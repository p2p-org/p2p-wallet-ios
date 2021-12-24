//
//  OrcaSwapV2.DetailsView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 03.12.2021.
//

import UIKit
import RxSwift
import RxCocoa
import BEPureLayout

extension OrcaSwapV2 {
    final class DetailsView: UIStackView {
        private lazy var ratesStack = RatesStackView(
            exchangeRateDriver: viewModel.exchangeRateDriver,
            sourceWalletDriver: viewModel.sourceWalletDriver,
            destinationWalletDriver: viewModel.destinationWalletDriver
        )
        private let slippageView = ClickableRow(title: L10n.maxPriceSlippage)
        private let payFeesWithView = ClickableRow(title: L10n.paySwapFeesWith)
        private lazy var feesView = DetailFeesView(feesDriver: viewModel.feesDriver)

        @Injected private var viewModel: OrcaSwapV2ViewModelType
        private let disposeBag = DisposeBag()

        init() {
            super.init(frame: .zero)

            layout()
            bind()
        }

        @available(*, unavailable)
        required init(coder: NSCoder) {
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
            viewModel.slippageDriver
                .drive { [weak slippageView] in
                    slippageView?.setValue(text: "\($0 * 100)%")
                }
                .disposed(by: disposeBag)

            viewModel.feePayingTokenDriver
                .drive { [weak payFeesWithView] in
                    payFeesWithView?.setValue(text: $0)
                }
                .disposed(by: disposeBag)

            slippageView.clickHandler = { [weak viewModel] in
                viewModel?.navigate(to: .chooseSlippage)
            }

            payFeesWithView.clickHandler = { [weak viewModel] in
                viewModel?.choosePayFee()
            }
        }
    }
}
