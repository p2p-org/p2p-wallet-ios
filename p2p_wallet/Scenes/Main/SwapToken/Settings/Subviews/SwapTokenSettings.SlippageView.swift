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
    final class SlippageView: UIStackView {
        private let slippageLabel = UILabel(
            text: L10n.maxPriceSlippage.uppercased(),
            textSize: 12,
            textColor: .h8e8e93
        )
        private let segmentedControl: SegmentedControl<SlippageType>
        private let customField = CustomSlippageField()
        private let descriptionView = DescriptionView()

        private let disposeBag = DisposeBag()
        private let viewModel: NewSwapTokenSettingsViewModelType

        init(viewModel: NewSwapTokenSettingsViewModelType) {
            self.viewModel = viewModel
            let slippageType = viewModel.slippageType
            segmentedControl = .init(
                items: viewModel.possibleSlippageTypes,
                selectedItem: slippageType,
                changeHandler: { [weak viewModel] selectedSlippage in
                    viewModel?.slippageSelected(selectedSlippage)
                }
            )

            switch slippageType {
            case .oneTenth, .fiveTenth, .one:
                break
            case let .custom(value):
                if let value = value {
                    customField.setText(String(value))
                }
            }

            super.init(frame: .zero)

            configureSelf()
            layout()
            bind()
        }

        @available(*, unavailable)
        required init(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func configureSelf() {
            axis = .vertical
            spacing = 8
        }

        private func layout() {
            let allSubviews = [slippageLabel, segmentedControl, customField, descriptionView]
            allSubviews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

            addArrangedSubviews {
                slippageLabel.padding(.init(only: .left, inset: 18))
                segmentedControl
                customField
                BEStackViewSpacing(20)
                descriptionView
            }
        }

        private func bind() {
            viewModel.customSlippageIsOpenedDriver
                .drive(onNext: { [weak self] in
                    self?.customField.isHidden = !$0
                    if $0 {
                        self?.customField.becomeFirstResponder()
                    } else {
                        self?.customField.endEditing(true)
                    }
                })
                .disposed(by: disposeBag)

            customField.rxText
                .distinctUntilChanged()
                .map { $0.flatMap(NumberFormatter().number) }
                .map { $0?.doubleValue }
                .bind { [weak self] in
                    self?.viewModel.customSlippageChanged($0)
                }
                .disposed(by: disposeBag)
        }
    }
}
