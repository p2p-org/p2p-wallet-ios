//
//  Onboarding.EnableBiometryVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

extension Onboarding {
    class EnableBiometryVC: BaseOnboardingVC {
        // MARK: - Dependencies
        @Injected private var viewModel: OnboardingViewModelType
        
        override func setUp() {
            super.setUp()
            let biometryType = viewModel.getBiometryType()
            switch biometryType {
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
                    self?.viewModel.enableBiometryLater()
                }
            }
        }
        
        override func buttonAcceptDidTouch() {
            viewModel.authenticateAndEnableBiometry(errorHandler: nil)
        }
        
        override func buttonDoThisLaterDidTouch() {
            viewModel.enableBiometryLater()
        }
    }
}
