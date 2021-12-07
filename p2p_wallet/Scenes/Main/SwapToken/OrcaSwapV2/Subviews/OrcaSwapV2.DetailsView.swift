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
        private let fromRatesView = DetailRatesView()
        private let toRatesView = DetailRatesView()
        private let slippageView = ClickableRow(title: L10n.maxPriceSlippage)
        private let payFeesWithView = ClickableRow(title: L10n.paySwapFeesWith)
        private let feesView = DetailFeesView()

        private let viewModel: OrcaSwapV2ViewModelType
        private let disposeBag = DisposeBag()

        init(viewModel: OrcaSwapV2ViewModelType) {
            self.viewModel = viewModel

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

            fromRatesView.autoSetDimension(.height, toSize: 21)
            toRatesView.autoSetDimension(.height, toSize: 21)
            slippageView.autoSetDimension(.height, toSize: 66)
            payFeesWithView.autoSetDimension(.height, toSize: 66)

            let ratesStack = UIStackView(
                axis: .vertical,
                spacing: 8,
                alignment: .fill
            ) {
                fromRatesView
                toRatesView
            }

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
            viewModel.fromExchangeRate
                .drive { [weak fromRatesView] in
                    fromRatesView?.isHidden = $0 == nil

                    if let rateContent = $0 {
                        fromRatesView?.setData(content: rateContent)
                    }
                }
                .disposed(by: disposeBag)

            viewModel.toExchangeRate
                .drive { [weak toRatesView] in
                    toRatesView?.isHidden = $0 == nil

                    if let rateContent = $0 {
                        toRatesView?.setData(content: rateContent)
                    }
                }
                .disposed(by: disposeBag)

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

            viewModel.feesContentDriver
                .drive { [weak feesView] loadable in
                    feesView?.isHidden = loadable.value == nil

                    if let content = loadable.value {
                        feesView?.setData(content: content)
                    }
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
