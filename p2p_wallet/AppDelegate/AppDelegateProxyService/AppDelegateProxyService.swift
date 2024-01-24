import UIKit

@objcMembers
final class AppDelegateProxyService: NSObject, UIApplicationDelegate {
    private let serviceAppDelegates: [AppDelegateService]

    override init() {
        let services: [AppDelegateService] = [
            AppflyerAppDelegateService(),
            DeeplinkAppDelegateService(),
            HistoryAppdelegateService(),
            LokaliseAppDelegateService(),
        ]
        serviceAppDelegates = services.compactMap { $0 }
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
        let result = serviceAppDelegates.compactMap {
            $0.application?(app, open: url, options: options)
        }

        return convert(result)
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        let result = serviceAppDelegates.compactMap {
            $0.application?(
                application,
                continue: userActivity,
                restorationHandler: restorationHandler
            )
        }

        return convert(result)
    }

    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        for serviceAppDelegate in serviceAppDelegates {
            serviceAppDelegate.application?(
                application,
                performActionFor: shortcutItem,
                completionHandler: completionHandler
            )
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        for serviceAppDelegate in serviceAppDelegates {
            serviceAppDelegate.applicationDidEnterBackground?(application)
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        for serviceAppDelegate in serviceAppDelegates {
            serviceAppDelegate.applicationWillEnterForeground?(application)
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        for serviceAppDelegate in serviceAppDelegates {
            serviceAppDelegate.application?(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        for serviceAppDelegate in serviceAppDelegates {
            serviceAppDelegate.application?(application, didFailToRegisterForRemoteNotificationsWithError: error)
        }
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        for serviceAppDelegate in serviceAppDelegates {
            serviceAppDelegate.application?(
                application,
                didReceiveRemoteNotification: userInfo,
                fetchCompletionHandler: completionHandler
            )
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        for serviceAppDelegate in serviceAppDelegates {
            serviceAppDelegate.applicationWillResignActive?(application)
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        for serviceAppDelegate in serviceAppDelegates {
            serviceAppDelegate.applicationDidBecomeActive?(application)
        }
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        for serviceAppDelegate in serviceAppDelegates {
            serviceAppDelegate.applicationDidReceiveMemoryWarning?(application)
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        for serviceAppDelegate in serviceAppDelegates {
            serviceAppDelegate.applicationWillTerminate?(application)
        }
    }

    private func convert(_ result: [Bool]) -> Bool {
        result.contains(true)
    }
}
