//
//  AppDelegate.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/22/20.
//

import Action
import BECollectionView
@_exported import BEPureLayout
import FeeRelayerSwift
import Firebase
import KeyAppKitLogger
import KeyAppUI
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

        FirebaseApp.configure()

        setupLoggers()

        // Sentry
        SentrySDK.start { options in
            options
                .dsn = .secretConfig("SENTRY_DSN")
            options.tracesSampleRate = 1.0
            #if DEBUG
                options.debug = true
                options.tracesSampleRate = 0.0
            #endif
            options.enableNetworkTracking = true
            options.enableOutOfMemoryTracking = true
        }

        setupRemoteConfig()

        // set app coordinator
        appCoordinator = AppCoordinator()
        appCoordinator!.start()
        window = appCoordinator?.window

        // notify notification Service
        notificationService.wasAppLaunchedFromPush(launchOptions: launchOptions)

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
        debugPrint("Failed to register: \(error)")
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
        let remoteConfig = RemoteConfig.remoteConfig()
        if Environment.current != .release {
            let settings = RemoteConfigSettings()
            // WARNING: Don't actually do this in production!
            settings.minimumFetchInterval = 0
            remoteConfig.configSettings = settings
        }

        let currentEndpoints = APIEndPoint.definedEndpoints
        if Environment.current != .release {
            FeatureFlagProvider.shared.fetchFeatureFlags(
                mainFetcher: MergingFlagsFetcher(
                    primaryFetcher: DebugMenuFeaturesProvider.shared,
                    secondaryFetcher: MergingFlagsFetcher(
                        primaryFetcher: defaultFlags,
                        secondaryFetcher: remoteConfig
                    )
                )
            ) { _ in
                self.changeEndpointIfNeeded(currentEndpoints: currentEndpoints)
            }
        } else {
            FeatureFlagProvider.shared.fetchFeatureFlags(
                mainFetcher: MergingFlagsFetcher(
                    primaryFetcher: remoteConfig,
                    secondaryFetcher: defaultFlags
                )
            ) { _ in
                self.changeEndpointIfNeeded(currentEndpoints: currentEndpoints)
            }
        }

        Defaults.isCoingeckoProviderDisabled = !RemoteConfig.remoteConfig()
            .configValue(forKey: Feature.coinGeckoPriceProvider.rawValue).boolValue
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
        navBarAppearence.shadowImage = UIImage()
        navBarAppearence.isTranslucent = true

        navBarAppearence.tintColor = .black
        barButtonAppearance.tintColor = .black
    }
}
