//
//  AppsFlyerAppDelegateService.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 31.01.2023.
//

import AppsFlyerLib
import Foundation
import AppTrackingTransparency

final class AppsFlyerAppDelegateService: NSObject, AppDelegateService {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        AppsFlyerLib.shared().appsFlyerDevKey = String.secretConfig("APPSFLYER_DEV_KEY")!
        AppsFlyerLib.shared().appleAppID = String.secretConfig("APPSFLYER_APP_ID")!
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        AppsFlyerLib.shared().handleOpen(url, options: options)
        return false
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
        return false
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        AppsFlyerLib.shared().registerUninstall(deviceToken)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        AppsFlyerLib.shared().start(completionHandler: { dictionary, error in
            if error != nil {
                print(error ?? "")
                return
            } else {
                print(dictionary ?? "")
                return
            }
        })
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .denied:
                    DefaultLogManager.shared.log(
                        event: "AppsFlyerLib ATTrackingManager AuthorizationSatus is denied",
                        logLevel: .info
                    )
                case .notDetermined:
                    DefaultLogManager.shared.log(
                        event: "AppsFlyerLib ATTrackingManager AuthorizationSatus is notDetermined",
                        logLevel: .debug
                    )
                case .restricted:
                    DefaultLogManager.shared.log(
                        event: "AppsFlyerLib ATTrackingManager AuthorizationSatus is restricted",
                        logLevel: .info
                    )
                case .authorized:
                    DefaultLogManager.shared.log(
                        event: "AppsFlyerLib ATTrackingManager AuthorizationSatus is authorized",
                        logLevel: .debug
                    )
                @unknown default:
                    DefaultLogManager.shared.log(
                        event: "AppsFlyerLib ATTrackingManager Invalid authorization status",
                        logLevel: .error
                    )
                }
            }
        }
    }
}
