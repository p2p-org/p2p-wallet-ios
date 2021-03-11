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
//        switcher.onTintColor = .h5887ff
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
                UIImageView(width: 24, height: 24, image: .settingsPincode, tintColor: .a3a5ba)
                    .padding(.init(all: 13), backgroundColor: .f6f6f8, cornerRadius: 12),
                UIView.col([
                    UILabel(text: L10n.pinCode, weight: .medium),
                    UILabel(text: L10n.defaultSecureCheck, textSize: 12, textColor: .textSecondary, numberOfLines: 0)
                ]).with(spacing: 5),
                UIImageView(width: 8, height: 13, image: .nextArrow, tintColor: .textBlack)
            ])
                .with(spacing: 16, alignment: .center, distribution: .fill)
                .padding(.init(x: 20, y: 14), backgroundColor: .textWhite)
                .onTap(self, action: #selector(buttonChangePinCodeDidTouch))
        ])
        
        let biometryMethod = LABiometryType.current
        if !biometryMethod.stringValue.isEmpty {
            stackView.insertArrangedSubview(
                UIView.row([
                    UIImageView(width: 24, height: 24, image: biometryMethod.icon, tintColor: .a3a5ba)
                        .padding(.init(all: 13), backgroundColor: .f6f6f8, cornerRadius: 12),
                    UIView.col([
                        UILabel(text: LABiometryType.current.stringValue, weight: .medium),
                        UILabel(text: L10n.willBeAsAPrimarySecureCheck, textSize: 12, textColor: .textSecondary, numberOfLines: 0)
                    ]).with(spacing: 5),
                    biometrySwitcher
                ])
                    .with(spacing: 16, alignment: .center, distribution: .fill)
                    .padding(.init(x: 20, y: 14), backgroundColor: .textWhite),
                at: 0
            )
        }
        
        biometrySwitcher.isOn = Defaults.isBiometryEnabled
    }
    
    @objc func switcherDidChange(_ switcher: UISwitch) {
        // prevent default's localAuth action
        let isAuthenticating = rootViewModel.isAuthenticating
        guard !isAuthenticating else {
            switcher.isOn.toggle()
            return
        }
        
        rootViewModel.isAuthenticating = true
        
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
                self?.rootViewModel.isAuthenticating = isAuthenticating
            }
        }
    }
    
    @objc func buttonChangePinCodeDidTouch() {
        show(ChangePinCodeVC(accountStorage: accountStorage), sender: nil)
    }
}
