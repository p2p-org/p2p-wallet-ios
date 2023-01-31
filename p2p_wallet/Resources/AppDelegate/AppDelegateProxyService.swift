//
//  AppDelegateProxyService.swift
//  p2p_wallet
//
//  Created by Ivan on 16.06.2022.
//

import UIKit

@objcMembers
final class AppDelegateProxyService: NSObject, UIApplicationDelegate {
    private let serviceAppDelegates: [AppDelegateService]

    override init() {
        var services: [AppDelegateService] = [
            GoogleAppDelegateService(),
            LoggersAppDelegateService(),
            NotificationsAppDelegateService(),
            IntercomAppDelegateService(),
            AppsFlyerAppDelegateService(),
            LokaliseAppDelegateService(),
        ]

        #if !RELEASE
            services.append(contentsOf: [
                DebugAppDelegateService(),
            ])
        #endif

        serviceAppDelegates = services
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let result = serviceAppDelegates.compactMap {
            $0.application?(
                application,
                didFinishLaunchingWithOptions: launchOptions
            )
        }

        return result.allSatisfy { $0 == true }
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        for serviceAppDelegate in serviceAppDelegates {
            let result: Bool = serviceAppDelegate.application?(app, open: url, options: options) ?? false

            if result {
                return true
            }
        }

        return false
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        for serviceAppDelegate in serviceAppDelegates {
            let result: Bool = serviceAppDelegate.application?(
                application,
                continue: userActivity,
                restorationHandler: restorationHandler
            ) ?? false

            if result {
                return true
            }
        }

        return false
    }

    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        serviceAppDelegates.forEach {
            $0.application?(
                application,
                performActionFor: shortcutItem,
                completionHandler: completionHandler
            )
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        serviceAppDelegates.forEach {
            $0.applicationDidEnterBackground?(application)
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        serviceAppDelegates.forEach {
            $0.applicationWillEnterForeground?(application)
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        serviceAppDelegates.forEach {
            $0.application?(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        serviceAppDelegates.forEach {
            $0.application?(application, didFailToRegisterForRemoteNotificationsWithError: error)
        }
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        serviceAppDelegates.forEach {
            $0.application?(
                application,
                didReceiveRemoteNotification: userInfo,
                fetchCompletionHandler: completionHandler
            )
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        serviceAppDelegates.forEach {
            $0.applicationWillResignActive?(application)
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        serviceAppDelegates.forEach {
            $0.applicationDidBecomeActive?(application)
        }
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        serviceAppDelegates.forEach {
            $0.applicationDidReceiveMemoryWarning?(application)
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        serviceAppDelegates.forEach {
            $0.applicationWillTerminate?(application)
        }
    }

    private func convert(_ result: [Bool]) -> Bool {
        result.contains(true)
    }
}
