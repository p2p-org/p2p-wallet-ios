//
//  AppflyerAppDelegateService.swift
//  p2p_wallet
//
//  Created by Chung Tran on 04/04/2023.
//

import Foundation
import AppsFlyerLib
import AppTrackingTransparency

final class AppflyerAppDelegateService: NSObject, AppDelegateService {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Set isDebug to true to see AppsFlyer debug logs
        #if DEBUG
        AppsFlyerLib.shared().isDebug = true
        #endif
        
        // Set app id
        let appsFlyerAppId: String
        #if !RELEASE
        appsFlyerAppId = String.secretConfig("APPSFLYER_APP_ID_FEATURE")!
        #else
        appsFlyerAppId = String.secretConfig("APPSFLYER_APP_ID")!
        #endif
        AppsFlyerLib.shared().appsFlyerDevKey = String.secretConfig("APPSFLYER_DEV_KEY")!
        AppsFlyerLib.shared().appleAppID = appsFlyerAppId
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        AppsFlyerLib.shared().registerUninstall(deviceToken)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        AppsFlyerLib.shared().handleOpen(url, options: options)
        return true // TODO
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
        return true // TODO
    }
    
    // MARK: - Life cycle

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
