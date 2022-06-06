//
//  SwapTokenSettings.SlippageView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 21.12.2021.
//

import BEPureLayout
import RxSwift
import UIKit

extension SwapTokenSettings {
    final class SlippageView: BECompositionView {
        private let disposeBag = DisposeBag()
        private let viewModel: NewSwapTokenSettingsViewModelType

        let customField = BERef<CustomSlippageField>()

        init(viewModel: NewSwapTokenSettingsViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        override func build() -> UIView {
            BEVStack(spacing: 8) {
                // Title
                UILabel(
                    text: L10n.maxPriceSlippage.uppercased(),
                    textSize: 12,
                    textColor: .h8e8e93
                ).padding(.init(only: .left, inset: 18))

                // Segment
                SegmentedControl(
                    items: viewModel.possibleSlippageTypes,
                    selectedItem: viewModel.slippageType,
                    changeHandler: { [weak self] selectedSlippage in
                        self?.viewModel.slippageSelected(selectedSlippage)

                        switch selectedSlippage {
                        case .custom:
                            self?.customField.view?.becomeFirstResponder()
                        default:
                            self?.customField.view?.endEditing(true)
                        }
                    }
                )

                // Custom field
                CustomSlippageField()
                    .bind(customField)
                    .setup { [weak self] textField in
                        switch self?.viewModel.slippageType {
                        case let .custom(value):
                            if let value = value { textField.setText(String(value)) }
                        default:
                            break
                        }

                        viewModel.customSlippageIsOpenedDriver
                            .map { !$0 }
                            .drive(textField.rx.isHidden)
                            .disposed(by: disposeBag)

                        textField.rxText
                            .distinctUntilChanged()
                            .map { $0.flatMap(NumberFormatter().number) }
                            .map { $0?.doubleValue }
                            .bind { [weak self] in
                                self?.viewModel.customSlippageChanged($0)
                            }
                            .disposed(by: disposeBag)
                    }

                // Description
                UIView(height: 20)
                DescriptionView()
            }.onTap { [weak self] in
                self?.customField.view?.endEditing(true)
            }
        }
    }
}
