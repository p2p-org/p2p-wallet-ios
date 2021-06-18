//
//  EnableBiometryVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import LocalAuthentication

class EnableBiometryVC: BaseOnboardingVC {
    enum Error: Swift.Error {
        case unknown
    }
    
    // MARK: - Properties
    let context = LAContext()
    let onboardingViewModel: OnboardingViewModel
    
    // MARK: - Initializers
    init(onboardingViewModel: OnboardingViewModel) {
        self.onboardingViewModel = onboardingViewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        onboardingViewModel.analyticsManager.log(event: .setupFaceidOpen)
    }
    
    override func setUp() {
        super.setUp()
        
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .touchID:
                firstDescriptionLabel.text = L10n.useYourTouchIDForQuickAccess
                secondDescriptionLabel.isHidden = true
                imageView.image = .touchId
                acceptButton.setTitle(L10n.useTouchId, for: .normal)
            case .faceID:
                firstDescriptionLabel.text = L10n.useYourFaceIDForQuickAccess
                secondDescriptionLabel.isHidden = true
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
        onboardingViewModel.setEnableBiometry(enabled)
    }
}
