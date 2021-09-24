//
//  Onboarding.EnableNotificationsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation
import UserNotifications

extension Onboarding {
    class EnableNotificationsVC: BaseOnboardingVC {
        // MARK: - Dependencies
        @Injected private var viewModel: OnboardingViewModelType
        @Injected private var analyticsManager: AnalyticsManagerType
        
        // MARK: - Methods
        override func viewDidLoad() {
            super.viewDidLoad()
            analyticsManager.log(event: .setupAllowPushOpen)
        }
        
        override func setUp() {
            super.setUp()
            acceptButton.setTitle(L10n.allowNotifications, for: .normal)
            
            firstDescriptionLabel.text = L10n.weSuggestYouAlsoToEnablePushNotifications
            secondDescriptionLabel.isHidden = true
            
            imageView.image = .turnOnNotification
        }
        
        override func buttonAcceptDidTouch() {
            UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge]) {[weak self] granted, _ in
                    print("Permission granted: \(granted)")
                    guard granted else {
                        UIApplication.shared.openAppSettings()
                        return
                    }
                        self?.getNotificationSettings()
                }
        }
        
        override func buttonDoThisLaterDidTouch() {
            viewModel.markNotificationsAsSet()
        }
        
        // MARK: - Helpers
        private func getNotificationSettings() {
            UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
                print("Notification settings: \(settings)")
                self?.analyticsManager.log(event: .setupAllowPushSelected(push: settings.authorizationStatus == .authorized))
                
                guard settings.authorizationStatus == .authorized else {
                    UIApplication.shared.openAppSettings()
                    return
                }
                DispatchQueue.main.async { [weak self] in
                    UIApplication.shared.registerForRemoteNotifications()
                    self?.viewModel.markNotificationsAsSet()
                }
            }
        }
    }

}
