//
//  EnableBiometryVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import LocalAuthentication

class EnableBiometryVC: SecuritySettingVC {
    enum Error: Swift.Error {
        case unknown
    }
    
    let context = LAContext()
    
    override var nextVC: UIViewController {EnableNotificationsVC()}
    
    override func setUp() {
        super.setUp()
        
        let label = UILabel(textSize: 21, weight: .medium, numberOfLines: 0, textAlignment: .center)
        let imageView = UIImageView(width: 64, height: 64)
        imageView.tintColor = .textBlack
        
        stackView.insertArrangedSubview(label, at: 1)
        stackView.insertArrangedSubview(imageView, at: 2)
        
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .touchID:
                label.text = L10n.useYourTouchIDForQuickAccess
                imageView.image = .touchId
                acceptButton.setTitle(L10n.useTouchId, for: .normal)
            case .faceID:
                label.text = L10n.useYourFaceIDForQuickAccess
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
