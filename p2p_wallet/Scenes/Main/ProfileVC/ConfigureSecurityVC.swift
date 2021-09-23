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
    
    @Injected private var accountStorage: KeychainAccountStorage
    let authenticationHandler: AuthenticationHandler
    @Injected private var analyticsManager: AnalyticsManagerType
    
    init(
        authenticationHandler: AuthenticationHandler
    ) {
        self.authenticationHandler = authenticationHandler
    }
    
    override func setUp() {
        title = L10n.security
        super.setUp()
        
        stackView.addArrangedSubviews([
            UIView.row([
                UIView.squareRoundedCornerIcon(image: .settingsPincode),
                UIView.col([
                    UILabel(text: L10n.pinCode, weight: .medium),
                    UILabel(text: L10n.defaultSecureCheck, textSize: 12, textColor: .textSecondary, numberOfLines: 0)
                ]).with(spacing: 5),
                UIImageView(width: 8, height: 13, image: .nextArrow, tintColor: .textBlack)
            ])
                .with(spacing: 16, alignment: .center, distribution: .fill)
                .padding(.init(x: 20, y: 14), backgroundColor: .contentBackground)
                .onTap(self, action: #selector(buttonChangePinCodeDidTouch))
        ])
        
        let biometryMethod = LABiometryType.current
        if !biometryMethod.stringValue.isEmpty {
            stackView.insertArrangedSubview(
                UIView.row([
                    UIView.squareRoundedCornerIcon(image: biometryMethod.icon),
                    UIView.col([
                        UILabel(text: LABiometryType.current.stringValue, weight: .medium),
                        UILabel(text: L10n.willBeAsAPrimarySecureCheck, textSize: 12, textColor: .textSecondary, numberOfLines: 0)
                    ]).with(spacing: 5),
                    biometrySwitcher
                ])
                    .with(spacing: 16, alignment: .center, distribution: .fill)
                    .padding(.init(x: 20, y: 14), backgroundColor: .contentBackground),
                at: 0
            )
        }
        
        biometrySwitcher.isOn = Defaults.isBiometryEnabled
    }
    
    @objc func switcherDidChange(_ switcher: UISwitch) {
        authenticationHandler.pauseAuthentication(true)
        
        // get context
        let context = LAContext()
        let reason = L10n.identifyYourself

        // evaluate Policy
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] (success, authenticationError) in
            DispatchQueue.main.async {
                if success {
                    Defaults.isBiometryEnabled.toggle()
                    self?.analyticsManager.log(event: .settingsSecuritySelected(faceId: Defaults.isBiometryEnabled))
                } else {
                    self?.showError(authenticationError ?? Error.unknown)
                    switcher.isOn.toggle()
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.authenticationHandler.pauseAuthentication(false)
            }
        }
    }
    
    @objc func buttonChangePinCodeDidTouch() {
        authenticationHandler.authenticate(
            presentationStyle: .init(
                title: L10n.enterCurrentPINCode,
                isRequired: false,
                isFullScreen: false,
                useBiometry: false,
                completion: { [weak self] in
                    // pin code vc
                    let vc = CreatePassCodeVC(promptTitle: L10n.newPINCode)
                    vc.disableDismissAfterCompletion = true
                    vc.completion = {[weak self, weak vc] _ in
                        guard let pincode = vc?.passcode else {return}
                        self?.accountStorage.save(pincode)
                        vc?.dismiss(animated: true) { [weak self] in
                            let vc = PinCodeChangedVC()
                            self?.present(vc, animated: true, completion: nil)
                        }
                    }

                    // navigation
                    let nc = BENavigationController()
                    nc.viewControllers = [vc]

                    // modal
                    let modalVC = WLIndicatorModalVC()
                    modalVC.add(child: nc, to: modalVC.containerView)

    //                modalVC.isModalInPresentation = true
                    self?.present(modalVC, animated: true, completion: nil)
                }
            )
        )
    }
}

private class PinCodeChangedVC: FlexibleHeightVC {
    override var padding: UIEdgeInsets { UIEdgeInsets(all: 20).modifying(dBottom: -20) }
    override var margin: UIEdgeInsets {UIEdgeInsets(all: 16).modifying(dBottom: -12)}
    init() {
        super.init(position: .center)
    }
    
    override func setUp() {
        super.setUp()
        stackView.addArrangedSubviews([
            UIImageView(width: 95+60, height: 95+60, image: .passcodeChanged)
                .centeredHorizontallyView,
            BEStackViewSpacing(0),
            UILabel(text: L10n.pinCodeChanged, textSize: 21, weight: .bold, numberOfLines: 0, textAlignment: .center),
            BEStackViewSpacing(30),
            WLButton.stepButton(type: .blue, label: L10n.goBackToProfile)
                .onTap(self, action: #selector(back))
        ])
    }
    
    override func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let pc = super.presentationController(forPresented: presented, presenting: presenting, source: source) as! PresentationController
        pc.roundedCorner = .allCorners
        pc.cornerRadius = 24
        return pc
    }
}
