//
//  ConfigureSecurityVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2020.
//

import Foundation
import LocalAuthentication

class ConfigureSecurityVC: ProfileVCBase {
    enum Error: Swift.Error {
        case unknown
    }
    
    lazy var biometrySwitcher: UISwitch = {
        let switcher = UISwitch()
        switcher.tintColor = .textWhite
        switcher.onTintColor = .black
        switcher.addTarget(self, action: #selector(switcherDidChange(_:)), for: .valueChanged)
        return switcher
    }()
    
    let accountStorage: KeychainAccountStorage
    let rootViewModel: RootViewModel
    init(accountStorage: KeychainAccountStorage, rootViewModel: RootViewModel) {
        self.accountStorage = accountStorage
        self.rootViewModel = rootViewModel
    }
    
    override func setUp() {
        title = L10n.security
        super.setUp()
        stackView.addArrangedSubviews([
            UIView.row([
                UIImageView(width: 44, height: 44, backgroundColor: .c4c4c4, cornerRadius: 22),
                UIView.col([
                    UILabel(text: LABiometryType.current.stringValue, textSize: 15, weight: .medium),
                    UILabel(text: L10n.willBeAsAPrimarySecureCheck, textSize: 12, textColor: .textSecondary, numberOfLines: 0)
                ]).with(spacing: 5),
                biometrySwitcher
            ])
                .with(spacing: 16, alignment: .center, distribution: .fill)
                .padding(.init(x: 0, y: 20)),
            UIView.row([
                UIImageView(width: 44, height: 44, backgroundColor: .c4c4c4, cornerRadius: 22),
                UIView.col([
                    UILabel(text: L10n.pinCode, textSize: 15, weight: .medium),
                    UILabel(text: L10n.defaultSecureCheck, textSize: 12, textColor: .textSecondary, numberOfLines: 0)
                ]).with(spacing: 5),
                UIImageView(width: 4.5, height: 9, image: .nextArrow, tintColor: .textBlack)
            ])
                .with(spacing: 16, alignment: .center, distribution: .fill)
                .padding(.init(x: 0, y: 20))
                .onTap(self, action: #selector(buttonChangePinCodeDidTouch))
        ])
        
        biometrySwitcher.isOn = Defaults.isBiometryEnabled
    }
    
    @objc func switcherDidChange(_ switcher: UISwitch) {
        // prevent default's localAuth action
        let shouldShowLocalAuth = rootViewModel.shouldShowLocalAuth
        rootViewModel.shouldShowLocalAuth = false
        
        // get context
        let context = LAContext()
        let reason = L10n.identifyYourself

        // evaluate Policy
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] (success, authenticationError) in
            DispatchQueue.main.async {
                if success {
                    Defaults.isBiometryEnabled.toggle()
                } else {
                    self?.showError(authenticationError ?? Error.unknown)
                    switcher.isOn.toggle()
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self?.rootViewModel.shouldShowLocalAuth = shouldShowLocalAuth
            }
        }
    }
    
    @objc func buttonChangePinCodeDidTouch() {
        show(ChangePinCodeVC(accountStorage: accountStorage), sender: nil)
    }
    
    override func buttonDoneDidTouch() {
        back()
    }
}
