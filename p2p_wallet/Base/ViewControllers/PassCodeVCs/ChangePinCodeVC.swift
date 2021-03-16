//
//  ChangePinCodeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/12/2020.
//

import Foundation
import LocalAuthentication

class ChangePinCodeVC: WLBottomSheet {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .hidden
    }
    
    enum Error: Swift.Error {
        case unknown
    }
    
    lazy var currentPinTextField = createTextField()
    lazy var newPinTextField = createTextField(textContentType: .newPassword)
    lazy var repeatNewPinTextField = createTextField()
    lazy var changePinButton = WLButton.stepButton(type: .black, label: L10n.changePINCode)
        .onTap(self, action: #selector(buttonChangePinDidTouch))
    
    let accountStorage: KeychainAccountStorage
    
    init(accountStorage: KeychainAccountStorage) {
        self.accountStorage = accountStorage
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        interactor = nil
        view.removeGestureRecognizer(panGestureRecognizer!)
    }
    
    override func setUp() {
        super.setUp()
        title = L10n.changePINCode
        
        stackView.addArrangedSubviews([
            createInput(title: L10n.currentPINCode, textField: currentPinTextField),
            BEStackViewSpacing(20),
            createInput(title: L10n.newPINCode, textField: newPinTextField),
            BEStackViewSpacing(20),
            createInput(title: L10n.repeatNewPINCode, textField: repeatNewPinTextField),
            BEStackViewSpacing(30),
            changePinButton
        ])
    }
    
    @objc func buttonChangePinDidTouch() {
        // check pin
        guard currentPinTextField.text == accountStorage.pinCode
        else {
            showAlert(title: L10n.incorrectPINCode, message: L10n.pleaseReEnterPINCode)
            return
        }
        
        guard newPinTextField.text?.count == 6 else {
            showAlert(title: L10n.incorrectPINCode, message: L10n.pinCodeMustHave6Digits)
            return
        }
        
        guard newPinTextField.text == repeatNewPinTextField.text else {
            showAlert(title: L10n.incorrectPINCode, message: L10n.pinCodesDoNotMatch)
            return
        }
        
        accountStorage.save(newPinTextField.text!)
        dismiss(animated: true) {
            UIApplication.shared.showDone(L10n.successfullyChangedPINCode)
        }
//        // prevent default's localAuth action
//        let shouldShowLocalAuth = AppDelegate.shared.shouldShowLocalAuth
//        AppDelegate.shared.shouldShowLocalAuth = false
//
//        // get context
//        let context = LAContext()
//        let reason = L10n.identifyYourself
//
//        // evaluate Policy
//        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] (success, authenticationError) in
//            DispatchQueue.main.async {
//                if success {
//                    guard let self = self else {return}
//                    AccountStorage.shared.save(self.newPinTextField.text!)
//                    self.dismiss(animated: true, completion: nil)
//                } else {
//                    self?.showError(authenticationError ?? Error.unknown)
//                }
//            }
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                AppDelegate.shared.shouldShowLocalAuth = shouldShowLocalAuth
//            }
//        }
    }
    
    private func createInput(title: String, textField: UITextField) -> UIView {
        let view = UIView(backgroundColor: .f5f5f5, cornerRadius: 16)
        view.col([
            UILabel(text: title, textSize: 12, textColor: .textSecondary),
            textField
        ], padding: .init(x: 16, y: 10))
            .with(spacing: 5)
        return view
    }
    
    private func createTextField(textContentType: UITextContentType = .password) -> UITextField {
        UITextField(
            font: .systemFont(ofSize: 15),
            textColor: .textBlack,
            keyboardType: .numberPad,
            placeholder: nil,
            autocorrectionType: .none,
            autocapitalizationType: UITextAutocapitalizationType.none,
            spellCheckingType: .none,
            textContentType: textContentType,
            isSecureTextEntry: true
        )
    }
}
