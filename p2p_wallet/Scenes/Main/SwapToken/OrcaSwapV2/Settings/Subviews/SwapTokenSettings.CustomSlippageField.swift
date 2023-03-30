//
//  CustomSlippageField.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 22.12.2021.
//

import BEPureLayout
import RxSwift
import UIKit

extension SwapTokenSettings {
    final class CustomSlippageField: WLFloatingPanelView {
        private let title = UILabel(text: L10n.customSlippage, textSize: 15)
        private let textField = BEDecimalTextField(
            font: .systemFont(ofSize: 15),
            textAlignment: .right,
            keyboardType: .decimalPad,
            placeholder: nil
        )
        private let percentLabel = UILabel(text: "%", textSize: 15)

        var rxText: Observable<String?> {
            textField.rx.text.asObservable()
        }

        init() {
            super.init(cornerRadius: 12, contentInset: .init(all: 18))

            textField.countAfterDecimalPoint = 2
            textField.maxNumber = 50
            textField.delegate = self
        }

        override func commonInit() {
            super.commonInit()
            stackView.axis = .horizontal

            let allSubviews = [title, textField, percentLabel]
            allSubviews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
            title.setContentHuggingPriority(.required, for: .horizontal)
            percentLabel.setContentHuggingPriority(.required, for: .horizontal)
            allSubviews.forEach(stackView.addArrangedSubview)
        }

        func setText(_ text: String) {
            textField.text = text
        }

        @discardableResult
        override func becomeFirstResponder() -> Bool {
            textField.becomeFirstResponder()
        }

        @discardableResult
        override func endEditing(_ force: Bool) -> Bool {
            textField.endEditing(force)
        }
    }
}

extension SwapTokenSettings.CustomSlippageField: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        if let textField = textField as? BEDecimalTextField {
            return textField.shouldChangeCharactersInRange(range, replacementString: string)
        }

        return true
    }
}
