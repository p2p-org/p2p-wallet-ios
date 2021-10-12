//
//  Settings.ConfigureSecurityViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/10/2021.
//

import Foundation
import LocalAuthentication

extension Settings {
    class ConfigureSecurityViewController: BaseViewController {
        lazy var biometrySwitcher: UISwitch = {
            let switcher = UISwitch()
            switcher.tintColor = .textWhite
    //        switcher.onTintColor = .h5887ff
            switcher.addTarget(self, action: #selector(switcherDidChange(_:)), for: .valueChanged)
            return switcher
        }()
        
        override func setUp() {
            super.setUp()
            navigationBar.titleLabel.text = L10n.security
            
            stackView.addArrangedSubviews {
                UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill) {
                    UIView.squareRoundedCornerIcon(image: .settingsPincode)
                    UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill) {
                        UILabel(text: L10n.pinCode, weight: .medium)
                        UILabel(text: L10n.defaultSecureCheck, textSize: 12, textColor: .textSecondary, numberOfLines: 0)
                    }
                    UIImageView(width: 8, height: 13, image: .nextArrow, tintColor: .textBlack)
                }
                    .padding(.init(x: 20, y: 14), backgroundColor: .contentBackground)
                    .onTap(self, action: #selector(buttonChangePinCodeDidTouch))
                
                UIView.spacer
            }
            
            let biometryMethod = LABiometryType.current
            if !biometryMethod.stringValue.isEmpty {
                var index = 2
                stackView.insertArrangedSubviews(at: &index) {
                    UIView.row([
                        UIView.squareRoundedCornerIcon(image: biometryMethod.icon),
                        UIView.col([
                            UILabel(text: LABiometryType.current.stringValue, weight: .medium),
                            UILabel(text: L10n.willBeAsAPrimarySecureCheck, textSize: 12, textColor: .textSecondary, numberOfLines: 0)
                        ]).with(spacing: 5),
                        biometrySwitcher
                    ])
                        .with(spacing: 16, alignment: .center, distribution: .fill)
                        .padding(.init(x: 20, y: 14), backgroundColor: .contentBackground)
                    
                    BEStackViewSpacing(1)
                }
            }
            
            biometrySwitcher.isOn = Defaults.isBiometryEnabled
        }
        
        @objc func switcherDidChange(_ switcher: UISwitch) {
            viewModel.setEnabledBiometry(switcher.isOn) { [weak self] error in
                self?.showError(error ?? SolanaSDK.Error.unknown)
                self?.biometrySwitcher.isOn.toggle()
            }
        }
        
        @objc func buttonChangePinCodeDidTouch() {
//            authenticationHandler.authenticate(
//                presentationStyle: .init(
//                    title: L10n.enterCurrentPINCode,
//                    isRequired: false,
//                    isFullScreen: false,
//                    useBiometry: false,
//                    completion: { [weak self] in
//                        // pin code vc
//                        let vc = CreatePassCodeVC(promptTitle: L10n.newPINCode)
//                        vc.disableDismissAfterCompletion = true
//                        vc.completion = {[weak self, weak vc] _ in
//                            guard let pincode = vc?.passcode else {return}
//                            self?.accountStorage.save(pincode)
//                            vc?.dismiss(animated: true) { [weak self] in
//                                let vc = PinCodeChangedVC()
//                                self?.present(vc, animated: true, completion: nil)
//                            }
//                        }
//
//                        // navigation
//                        let nc = BENavigationController()
//                        nc.viewControllers = [vc]
//
//                        // modal
//                        let modalVC = WLIndicatorModalVC()
//                        modalVC.add(child: nc, to: modalVC.containerView)
//
//        //                modalVC.isModalInPresentation = true
//                        self?.present(modalVC, animated: true, completion: nil)
//                    }
//                )
//            )
        }
    }
}
