//
//  EnableBiometryVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import LocalAuthentication

class EnableBiometryVC: OnboardingVC {
    enum Error: Swift.Error {
        case unknown
    }
    
    let context = LAContext()
    
    override var nextVC: UIViewController {
        EnableNotificationsVC()
    }
    
    override func setUp() {
        super.setUp()
        
        // add imageView
        let imageView = UIImageView(width: 64, height: 64, tintColor: .white)
        let spacer2 = UIView.spacer
        
        var index = 3
        stackView.insertArrangedSubviewsWithCustomSpacing([
            imageView
                .centeredHorizontallyView,
            spacer2
        ], at: &index)
        
        spacer1.heightAnchor.constraint(equalTo: spacer2.heightAnchor)
            .isActive = true
        
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .touchID:
                titleLabel.text = L10n.enableTouchID
                descriptionLabel.text = L10n.useYourTouchIDForQuickAccess
                imageView.image = .touchId
                acceptButton.setTitle(L10n.useTouchId, for: .normal)
            case .faceID:
                titleLabel.text = L10n.enableFaceID
                descriptionLabel.text = L10n.useYourFaceIDForQuickAccess
                imageView.image = .faceId
                acceptButton.setTitle(L10n.useFaceId, for: .normal)
            default:
                showAlert(title: L10n.unsupported.uppercaseFirst, message: L10n.yourDeviceDoesNotSupportBiometricsAuthentication) { _ in
                    self.handleIsBiometryEnabled(false)
                }
            }
        } else {
            if let error = error {
                showError(error, completion: {
                    self.handleIsBiometryEnabled(false)
                })
            } else {
                showAlert(title: L10n.unsupported.uppercaseFirst, message: L10n.yourDeviceDoesNotSupportBiometricsAuthentication) { _ in
                    self.handleIsBiometryEnabled(false)
                }
            }
        }
    }
    
    override func buttonAcceptDidTouch() {
        let reason = L10n.identifyYourself

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] (success, authenticationError) in

            DispatchQueue.main.async {
                if success {
                    self?.handleIsBiometryEnabled(true)
                } else {
                    self?.showError(authenticationError ?? Error.unknown)
                }
            }
        }
    }
    
    override func buttonDoThisLaterDidTouch() {
        handleIsBiometryEnabled(false)
    }
    
    func handleIsBiometryEnabled(_ enabled: Bool) {
        Defaults.isBiometryEnabled = enabled
        Defaults.didSetEnableBiometry = true
        next()
    }
}
