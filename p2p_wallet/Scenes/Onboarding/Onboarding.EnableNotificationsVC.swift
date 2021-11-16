//
//  Onboarding.EnableNotificationsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation
import UIKit

extension Onboarding {
    class EnableNotificationsVC: BaseVC {
        // MARK: - Dependencies
        @Injected private var viewModel: OnboardingViewModelType
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            // navigation bar
            let navigationBar = WLNavigationBar(forAutoLayout: ())
            navigationBar.backButton.isHidden = true
            
            let skipButton = UIButton(label: L10n.skip, textColor: .h5887ff)
                .onTap(self, action: #selector(buttonSkipDidTouch))
            navigationBar.rightItems.addArrangedSubview(skipButton)
            
            view.addSubview(navigationBar)
            navigationBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
            
            // explanation view
            let explanationView = UILabel(
                text: L10n.allowPushNotificationsSoYouDonTMissAnyImportantUpdatesOnYourAccount,
                textSize: 15,
                textColor: .black,
                numberOfLines: 0
            )
                .padding(.init(all: 18), backgroundColor: .fafafc, cornerRadius: 12)
        }
        
        @objc private func buttonAcceptDidTouch() {
            viewModel.requestRemoteNotifications()
        }
        
        @objc private func buttonSkipDidTouch() {
            viewModel.markNotificationsAsSet()
        }
    }
}
