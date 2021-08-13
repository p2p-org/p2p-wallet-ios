//
//  SwapToken.SlippageSettingsViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/08/2021.
//

import Foundation

extension SwapToken {
    class SlippageSettingsViewController: SettingsBaseViewController {
        // MARK: - Properties
        private let quickSelectableSlippages: [Double] = [0.1, 0.5, 1, 5]
        private var slippage: Double = Defaults.slippage * 100
        private var shouldShowTextField = false
        private var isShowingTextField = false
        var completion: ((Double) -> Void)?
        private var keyboardHeight: CGFloat = 0
        
        // MARK: - Subviews
        private lazy var slippagesView = UIStackView(
            axis: .horizontal,
            spacing: 10,
            alignment: .fill,
            distribution: .fillEqually,
            arrangedSubviews:
                quickSelectableSlippages.enumerated().map {createButton(text: "\($1.toString(groupingSeparator: nil))%", tag: $0)} +
                [
                    UIView(backgroundColor: .grayPanel, cornerRadius: 12)
                        .withCenteredChild(
                            UIImageView(width: 25, height: 24, image: .slippageEdit)
                        )
                        .onTap(self, action: #selector(buttonCustomSlippageDidTouch))
                ]
        )
        private lazy var customSlippageTextField: PercentSuffixTextField = {
            let tf = PercentSuffixTextField(
                height: 56,
                backgroundColor: .f6f6f8.onDarkMode(.h1b1b1b),
                cornerRadius: 12,
                font: .systemFont(ofSize: 17),
                keyboardType: .decimalPad,
                placeholder: nil,
                autocorrectionType: .no,
                autocapitalizationType: UITextAutocapitalizationType.none,
                spellCheckingType: .no,
                horizontalPadding: 16,
                rightView: textFieldClearButton,
                rightViewMode: .whileEditing
            )
            tf.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
            return tf
        }()
        private lazy var textFieldClearButton = UIView(forAutoLayout: ())
            .withModifier {view in
                let clearButton = UIImageView(width: 24, height: 24, image: .textfieldClear)
                    .onTap(self, action: #selector(buttonClearTextFieldDidTouch))
                view.addSubview(clearButton)
                clearButton.autoPinEdge(toSuperviewEdge: .leading, withInset: 8)
                clearButton.autoPinEdge(toSuperviewEdge: .trailing, withInset: 16)
                clearButton.autoAlignAxis(toSuperviewAxis: .horizontal)
                return view
            }
        private lazy var doneButton = WLButton.stepButton(type: .blue, label: L10n.done)
            .onTap(self, action: #selector(buttonDoneDidTouch))
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            title = L10n.slippageSettings
            
            if self == navigationController?.viewControllers.first {
                hideBackButton()
            }
            
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
            
            customSlippageTextField.delegate = self
            customSlippageTextField.text = slippage.toString(maximumFractionDigits: 9, groupingSeparator: "")
            reloadData()
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        override func setUpContent(stackView: UIStackView) {
            stackView.addArrangedSubviews {
                UILabel(
                    text: L10n
                        .SlippageRefersToTheDifferenceBetweenTheExpectedPriceOfATradeAndThePriceAtWhichTheTradeIsExecuted
                        .slippageCanOccurAtAnyTimeButIsMostPrevalentDuringPeriodsOfHigherVolatilityWhenMarketOrdersAreUsed, textColor: .textSecondary, numberOfLines: 0
                )
                slippagesView
                customSlippageTextField
                doneButton
            }
        }
        
        func reloadData() {
            var selectedView: UIView!
            if !shouldShowTextField,
               let index = quickSelectableSlippages.firstIndex(of: slippage)
            {
                selectedView = slippagesView.arrangedSubviews[index]
            } else {
                selectedView = slippagesView.arrangedSubviews.last
                shouldShowTextField = true
            }
            
            // config styles
            let deselectedViews = slippagesView.arrangedSubviews.filter {$0 != selectedView}
            selectedView.backgroundColor = .white.onDarkMode(.h1b1b1b)
            selectedView.border(width: 1, color: .h5887ff.onDarkMode(.h1b1b1b))
            
            deselectedViews.forEach {
                $0.backgroundColor = .grayPanel
                $0.border(width: 0, color: .clear)
            }
            
            customSlippageTextField.isHidden = !shouldShowTextField
            
            // force relayout modal when needed
            if shouldShowTextField != isShowingTextField {
                updatePresentationLayout()
                isShowingTextField.toggle()
            }
        }
        
        // MARK: - Helpers
        private func createButton(text: String, tag: Int) -> UIView {
            UILabel(text: text, weight: .medium, textColor: .a3a5ba, textAlignment: .center)
                .padding(.init(x: 10, y: 14), backgroundColor: .grayPanel, cornerRadius: 12)
                .withTag(tag)
                .onTap(self, action: #selector(buttonSelectableSlippageDidTouch(_:)))
        }
        
        @objc private func buttonSelectableSlippageDidTouch(_ sender: UIGestureRecognizer) {
            if let index = sender.view?.tag {
                shouldShowTextField = false
                slippage = quickSelectableSlippages[index]
                customSlippageTextField.resignFirstResponder()
                reloadData()
            }
        }
        
        @objc private func buttonCustomSlippageDidTouch() {
            shouldShowTextField = true
            reloadData()
            customSlippageTextField.becomeFirstResponder()
        }
        
        @objc private func buttonDoneDidTouch() {
            if isShowingTextField,
               let slippage = customSlippageTextField.text?.double
            {
                self.slippage = slippage
            }
            completion?(slippage)
            back()
        }
        
        @objc func keyboardWillShow(notification: NSNotification) {
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue
            {
                keyboardHeight = keyboardSize.height
            }
            updatePresentationLayout()
        }
        
        @objc func keyboardWillHide(notification: NSNotification) {
            keyboardHeight = 0
            updatePresentationLayout()
        }
        
        private func updatePresentationLayout() {
            (navigationController as? SettingsNavigationController)?.updatePresentationLayout(animated: true)
        }
        
        @objc private func buttonClearTextFieldDidTouch() {
            customSlippageTextField.text = nil
            customSlippageTextField.sendActions(for: .editingChanged)
        }
        
        @objc private func textFieldDidChange() {
            if customSlippageTextField.text == nil || customSlippageTextField.text?.isEmpty == true
            {
                textFieldClearButton.isHidden = true
            } else {
                textFieldClearButton.isHidden = false
            }
        }
        
        override func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
            super.calculateFittingHeightForPresentedView(targetWidth: targetWidth) + keyboardHeight
        }
    }
}

extension SwapToken.SlippageSettingsViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == customSlippageTextField {
            return customSlippageTextField.shouldChangeCharactersInRange(range, replacementString: string)
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.border(width: 1, color: .h5887ff)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.border(width: 1, color: .f6f6f8.onDarkMode(.h1b1b1b))
    }
}
