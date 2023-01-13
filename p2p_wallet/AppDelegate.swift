//
//  AppDelegate.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/22/20.
//

import Action
import AppsFlyerLib
import AppTrackingTransparency
@_exported import BEPureLayout
import FeeRelayerSwift
import Firebase
import KeyAppKitLogger
import KeyAppUI
import Resolver
import Sentry
import SolanaSwift
import SwiftNotificationCenter
@_exported import SwiftyUserDefaults
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var appCoordinator: AppCoordinator?

    @Injected private var notificationService: NotificationService

    static var shared: AppDelegate {
        UIApplication.shared.delegate as! AppDelegate
    }

    private lazy var proxyAppDelegate = AppDelegateProxyService()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // TODO: - Support custom fiat later
        Defaults.fiat = .usd
        
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        // TODO: - Swizzle localization later
//        Bundle.swizzleLocalization()
        IntercomStartingConfigurator().configure()

        setupNavigationAppearance()

        FirebaseApp.configure()

        setupLoggers()
        setupAppsFlyer()
        setupDefaultCurrency()

        // Sentry
        #if !DEBUG
        SentrySDK.start { options in
            options
                .dsn = .secretConfig("SENTRY_DSN")
            options.tracesSampleRate = 1.0
//            #if DEBUG
//                options.debug = true
//                options.tracesSampleRate = 0.0
//            #endif
            options.enableNetworkTracking = true
            options.enableOutOfMemoryTracking = true
        }
        #endif

        // set app coordinator
        appCoordinator = AppCoordinator()
        appCoordinator!.start()
        window = appCoordinator?.window

        // notify notification Service
        notificationService.wasAppLaunchedFromPush(launchOptions: launchOptions)

        UIViewController.swizzleViewDidDisappear()
        UIViewController.swizzleViewDidAppear()

        return proxyAppDelegate.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task.detached(priority: .background) { [unowned self] in
            await notificationService.sendRegisteredDeviceToken(deviceToken)
        }
        AppsFlyerLib.shared().registerUninstall(deviceToken)
        proxyAppDelegate.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        DefaultLogManager.shared.log(
            event: "Application: didFailToRegisterForRemoteNotificationsWithError: \(error)",
            logLevel: .debug
        )
        proxyAppDelegate.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }

    func application(_: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        var result = false
        Broadcaster.notify(AppUrlHandler.self) { result = result || $0.handle(url: url, options: options) }
        AppsFlyerLib.shared().handleOpen(url, options: options)
        return result
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
        return proxyAppDelegate.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        notificationService.didReceivePush(userInfo: userInfo)
        proxyAppDelegate.application(
            application,
            didReceiveRemoteNotification: userInfo,
            fetchCompletionHandler: completionHandler
        )
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        #if DEBUG
            AppsFlyerLib.shared().isDebug = true
            AppsFlyerLib.shared().useUninstallSandbox = true
        #endif
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
        AppsFlyerLib.shared().start()
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
        proxyAppDelegate.applicationDidBecomeActive(application)
    }

    // MARK: - AppsFlyer

    func setupAppsFlyer() {
        AppsFlyerLib.shared().appsFlyerDevKey = String.secretConfig("APPSFLYER_DEV_KEY") ?? ""
        AppsFlyerLib.shared().appleAppID = String.secretConfig("APPSFLYER_APP_ID") ?? ""
        AppsFlyerLib.shared().deepLinkDelegate = self
    }

    func setupLoggers() {
        var loggers: [LogManagerLogger] = [
            SentryLogger(),
        ]
        if Environment.current == .debug {
            loggers.append(LoggerSwiftLogger())
        }

        SolanaSwift.Logger.setLoggers(loggers as! [SolanaSwiftLogger])
        FeeRelayerSwift.Logger.setLoggers(loggers as! [FeeRelayerSwiftLogger])
        KeyAppKitLogger.Logger.setLoggers(loggers as! [KeyAppKitLoggerType])
        DefaultLogManager.shared.setProviders(loggers)
    }

    private func setupNavigationAppearance() {
        let barButtonAppearance = UIBarButtonItem.appearance()
        let navBarAppearence = UINavigationBar.appearance()
        navBarAppearence.backIndicatorImage = .navigationBack
            .withRenderingMode(.alwaysTemplate)
            .withAlignmentRectInsets(.init(top: 0, left: -12, bottom: 0, right: 0))
        navBarAppearence.backIndicatorTransitionMaskImage = .navigationBack
            .withRenderingMode(.alwaysTemplate)
            .withAlignmentRectInsets(.init(top: 0, left: -12, bottom: 0, right: 0))
        barButtonAppearance.setBackButtonTitlePositionAdjustment(
            .init(horizontal: -UIScreen.main.bounds.width * 1.5, vertical: 0),
            for: .default
        )
        navBarAppearence.titleTextAttributes = [.foregroundColor: UIColor.black]
        navBarAppearence.tintColor = Asset.Colors.night.color
        barButtonAppearance.tintColor = Asset.Colors.night.color

        navBarAppearence.shadowImage = UIImage()
        navBarAppearence.isTranslucent = true
    }

    func setupDefaultCurrency() {
        guard Defaults.fiat != .usd else { return }
        // Migrate all users to default currency
        Defaults.fiat = .usd
    }
}

extension AppDelegate: DeepLinkDelegate {
    func didResolveDeepLink(_: DeepLinkResult) {}
}
