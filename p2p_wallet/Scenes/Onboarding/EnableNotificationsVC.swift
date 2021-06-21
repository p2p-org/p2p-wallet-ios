//
//  EnableNotificationsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation
import UserNotifications

class EnableNotificationsVC: BaseOnboardingVC {
    // MARK: - Properties
    let onboardingViewModel: OnboardingViewModel
    
    // MARK: - Inititalizers
    init(onboardingViewModel: OnboardingViewModel) {
        self.onboardingViewModel = onboardingViewModel
        super.init()
    }
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        onboardingViewModel.analyticsManager.log(event: .setupAllowPushOpen)
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
        onboardingViewModel.markNotificationsAsSet()
    }
    
    // MARK: - Helpers
    private func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            print("Notification settings: \(settings)")
            self?.onboardingViewModel.analyticsManager.log(event: .setupAllowPushSelected(push: settings.authorizationStatus == .authorized))
            
            guard settings.authorizationStatus == .authorized else {
                UIApplication.shared.openAppSettings()
                return
            }
            DispatchQueue.main.async { [weak self] in
                UIApplication.shared.registerForRemoteNotifications()
                self?.onboardingViewModel.markNotificationsAsSet()
            }
        }
    }
}
