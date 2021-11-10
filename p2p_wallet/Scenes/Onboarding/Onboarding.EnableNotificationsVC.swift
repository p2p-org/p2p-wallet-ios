//
//  Onboarding.EnableNotificationsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation

extension Onboarding {
    class EnableNotificationsVC: BaseOnboardingVC {
        // MARK: - Dependencies
        @Injected private var viewModel: OnboardingViewModelType
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            acceptButton.setTitle(L10n.allowNotifications, for: .normal)
            
            firstDescriptionLabel.text = L10n.weSuggestYouAlsoToEnablePushNotifications
            secondDescriptionLabel.isHidden = true
            
            imageView.image = .turnOnNotification
        }
        
        override func buttonAcceptDidTouch() {
            viewModel.requestRemoteNotifications()
        }
        
        override func buttonDoThisLaterDidTouch() {
            viewModel.markNotificationsAsSet()
        }
    }
}
