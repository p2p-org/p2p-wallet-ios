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
    
    override var nextVC: UIViewController {EnableNotificationsVC()}
    
    override func setUp() {
        super.setUp()
        acceptButton.setTitle(L10n.useFaceId, for: .normal)
        
        let label = UILabel(text: L10n.useYourFaceIDForQuickAccess, textSize: 21, weight: .medium, numberOfLines: 0, textAlignment: .center)
        let imageView = UIImageView(width: 64, height: 64, image: .faceId)
        
        stackView.insertArrangedSubview(label, at: 1)
        stackView.insertArrangedSubview(imageView, at: 2)
    }
    
    override func buttonAcceptDidTouch() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify yourself!"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] (success, authenticationError) in

                DispatchQueue.main.async {
                    if success {
                        self?.handleIsBiometryEnabled(true)
                    } else {
                        self?.showError(error ?? authenticationError ?? Error.unknown)
                    }
                }
            }
        } else {
            showAlert(title: L10n.unsupported.uppercaseFirst, message: L10n.yourDeviceDoesNotSupportBiometricsAuthentication)
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
