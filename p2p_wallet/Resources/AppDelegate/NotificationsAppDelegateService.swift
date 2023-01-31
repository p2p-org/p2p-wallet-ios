//
//  NotificationsAppDelegateService.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 31.01.2023.
//

import Foundation
import Resolver

final class NotificationsAppDelegateService: NSObject, AppDelegateService {
    @Injected private var notificationService: NotificationService

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Notify notification service
        notificationService.wasAppLaunchedFromPush(launchOptions: launchOptions)
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task.detached(priority: .background) { [unowned self] in
            await notificationService.sendRegisteredDeviceToken(deviceToken)
        }
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        notificationService.didReceivePush(userInfo: userInfo)
    }
}
