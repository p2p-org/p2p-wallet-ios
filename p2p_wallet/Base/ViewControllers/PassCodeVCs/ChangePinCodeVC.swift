//
//  ChangePinCodeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/12/2020.
//

import Foundation

class ChangePinCodeVC: WLBottomSheet {
    lazy var currentPinTextField = createTextField()
    lazy var newPinTextField = createTextField(textContentType: .newPassword)
    lazy var repeatNewPinTextField = createTextField()
    lazy var changePinButton = WLButton.stepButton(type: .main, label: L10n.changePINCode)
    
    override func setUp() {
        super.setUp()
        title = L10n.changePINCode
        
        interactor = nil
        view.removeGestureRecognizer(panGestureRecognizer!)
        
        stackView.addArrangedSubviews([
            createInput(title: L10n.currentPINCode, textField: currentPinTextField),
            createInput(title: L10n.newPINCode, textField: newPinTextField),
            createInput(title: L10n.repeatNewPINCode, textField: repeatNewPinTextField),
            changePinButton
        ], withCustomSpacings: [20, 20, 30])
    }
    
    private func createInput(title: String, textField: UITextField) -> UIView {
        let view = UIView(backgroundColor: .f5f5f5, cornerRadius: 16)
        view.col([
            UILabel(text: title, textSize: 12, textColor: .secondary),
            textField
        ], padding: .init(x: 16, y: 10))
            .with(spacing: 5)
        return view
    }
    
    private func createTextField(textContentType: UITextContentType = .password) -> UITextField {
        UITextField(font: .systemFont(ofSize: 15), textColor: .textBlack, keyboardType: .numberPad, placeholder: nil, autocorrectionType: .none, autocapitalizationType: UITextAutocapitalizationType.none, spellCheckingType: .none, textContentType: textContentType, isSecureTextEntry: true)
    }
}
