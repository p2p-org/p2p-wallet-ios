//
//  AppDelegate.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/22/20.
//

@_exported import BEPureLayout
import FeeRelayerSwift
import Firebase
import LoggerService
import Resolver
import Sentry
import SolanaSwift
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
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        // TODO: - Swizzle localization later
//        Bundle.swizzleLocalization()
        IntercomStartingConfigurator().configure()

        setupNavigationAppearance()
        setupTabBarAppearance()

        FirebaseApp.configure()

        setupLoggers()

        // Sentry
        SentrySDK.start { options in
            options
                .dsn = .secretConfig("SENTRY_DSN")
            #if DEBUG
                options.debug = true
            #endif
            options.tracesSampleRate = 1.0
            options.enableNetworkTracking = true
            options.enableOutOfMemoryTracking = true
        }

        // set app coordinator
        appCoordinator = AppCoordinator()
        appCoordinator!.start()
        window = appCoordinator?.window

        // notify notification Service
        notificationService.wasAppLaunchedFromPush(launchOptions: launchOptions)

        setupDefaultFlags()
        FeatureFlagProvider.shared.fetchFeatureFlags(mainFetcher: defaultFlags)
        setupRemoteConfig()

        UIViewController.swizzleViewDidDisappear()

        return proxyAppDelegate.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task.detached(priority: .background) { [unowned self] in
            await notificationService.sendRegisteredDeviceToken(deviceToken)
        }
        proxyAppDelegate.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register: \(error)")
        proxyAppDelegate.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
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

    private func setupRemoteConfig() {
        #if !RELEASE
            let settings = RemoteConfigSettings()
            // WARNING: Don't actually do this in production!
            settings.minimumFetchInterval = 0
            RemoteConfig.remoteConfig().configSettings = settings
        #endif

        let currentEndpoints = APIEndPoint.definedEndpoints
        #if !RELEASE
            FeatureFlagProvider.shared.fetchFeatureFlags(
                mainFetcher: MergingFlagsFetcher(
                    primaryFetcher: DebugMenuFeaturesProvider.shared,
                    secondaryFetcher: MergingFlagsFetcher(
                        primaryFetcher: defaultFlags,
                        secondaryFetcher: RemoteConfig.remoteConfig()
                    )
                )
            ) { _ in
                self.changeEndpointIfNeeded(currentEndpoints: currentEndpoints)
            }
        #else
            FeatureFlagProvider.shared.fetchFeatureFlags(
                mainFetcher: MergingFlagsFetcher(
                    primaryFetcher: RemoteConfig.remoteConfig(),
                    secondaryFetcher: defaultFlags
                )
            ) { _ in
                self.changeEndpointIfNeeded(currentEndpoints: currentEndpoints)
            }
        #endif

        Defaults.isCoingeckoProviderDisabled = !RemoteConfig.remoteConfig()
            .configValue(forKey: Feature.coinGeckoPriceProvider.rawValue).boolValue
    }

    private func setupTabBarAppearance() {
        let standardAppearance = UITabBarAppearance()
        standardAppearance.backgroundColor = .clear
        standardAppearance.backgroundEffect = UIBlurEffect(style: .regular)
        standardAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.h6f7d8d,
        ]
        standardAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.h2b2b2b,
        ]
        standardAppearance.stackedItemPositioning = .automatic
        standardAppearance.shadowImage = nil
        standardAppearance.shadowColor = nil
        UITabBar.appearance().standardAppearance = standardAppearance
        UITabBar.appearance().tintColor = .h2b2b2b
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = standardAppearance
        }
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
        LoggerService.Logger.setLoggers(loggers as! [KeyAppKitLogger])
    }

    private func changeEndpointIfNeeded(currentEndpoints: [APIEndPoint]) {
        let newEndpoints = APIEndPoint.definedEndpoints
        guard currentEndpoints != newEndpoints else { return }
        if !(newEndpoints.contains { $0 == Defaults.apiEndPoint }),
           let firstEndpoint = newEndpoints.first
        {
            Resolver.resolve(ChangeNetworkResponder.self).changeAPIEndpoint(to: firstEndpoint)
        }
    }

    private func setupNavigationAppearance() {
        let barButtonAppearance = UIBarButtonItem.appearance()
        let navBarAppearence = UINavigationBar.appearance()
        navBarAppearence.backIndicatorImage = .navigationBack
            .withRenderingMode(.alwaysTemplate)
            .withAlignmentRectInsets(.init(top: 0, left: -6, bottom: 0, right: 0))
        navBarAppearence.backIndicatorTransitionMaskImage = .navigationBack
            .withRenderingMode(.alwaysTemplate)
            .withAlignmentRectInsets(.init(top: 0, left: -6, bottom: 0, right: 0))
        barButtonAppearance.setBackButtonTitlePositionAdjustment(
            .init(horizontal: -UIScreen.main.bounds.width * 1.5, vertical: 0),
            for: .default
        )
        navBarAppearence.titleTextAttributes = [.foregroundColor: UIColor.black]
        navBarAppearence.tintColor = .black
        barButtonAppearance.tintColor = .black
    }
}
