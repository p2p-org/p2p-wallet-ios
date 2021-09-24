//
//  Onboarding.EnableBiometryVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import LocalAuthentication

extension Onboarding {
    class EnableBiometryVC: BaseOnboardingVC {
        enum Error: Swift.Error {
            case unknown
        }
        
        // MARK: - Dependencies
        @Injected private var viewModel: OnboardingViewModelType
        @Injected private var analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        let context = LAContext()
        
        // MARK: - Methods
        override func viewDidLoad() {
            super.viewDidLoad()
            analyticsManager.log(event: .setupFaceidOpen)
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
                    showAlert(title: L10n.unsupported.uppercaseFirst, message: L10n.yourDeviceDoesNotSupportBiometricsAuthentication)
                    {[weak self] _ in
                        self?.handleIsBiometryEnabled(false)
                    }
                }
            } else {
                if let error = error {
                    showError(error, completion: { [weak self] in
                        self?.handleIsBiometryEnabled(false)
                    })
                } else {
                    showAlert(title: L10n.unsupported.uppercaseFirst, message: L10n.yourDeviceDoesNotSupportBiometricsAuthentication) { [weak self] _ in
                        self?.handleIsBiometryEnabled(false)
                    }
                }
            }
        }
        
        override func buttonAcceptDidTouch() {
            let reason = L10n.identifyYourself

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { (success, authenticationError) in

                DispatchQueue.main.async { [weak self] in
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
            viewModel.setEnableBiometry(enabled)
        }
    }
}
