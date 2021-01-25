//
//  EnableNotificationsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation
import UserNotifications
import SwiftUI

class EnableNotificationsVC: SecuritySettingVC {
    override var nextVC: UIViewController { WellDoneVC() }
    
    override func setUp() {
        super.setUp()
        acceptButton.setTitle(L10n.enableNow, for: .normal)
        
        titleLabel.text = L10n.almostDone
        descriptionLabel.text = L10n.weSuggestYouAlsoToEnablePushNotifications
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
        Defaults.didSetEnableNotifications = true
        super.buttonDoThisLaterDidTouch()
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else {
                UIApplication.shared.openAppSettings()
                return
            }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
                Defaults.didSetEnableNotifications = true
                self.next()
            }
        }
    }
}

@available(iOS 13, *)
struct EnableNotificationsVC_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UIViewControllerPreview {
                EnableNotificationsVC()
            }
            .previewDevice("iPhone SE (2nd generation)")
        }
    }
}
