//
//  AppDelegate.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/22/20.
//

import Action
import BECollectionView
@_exported import BEPureLayout
import Firebase
import Resolver
import Sentry
import SolanaSwift
@_exported import SwiftyUserDefaults
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    @Injected private var notificationService: NotificationService

    static var shared: AppDelegate {
        UIApplication.shared.delegate as! AppDelegate
    }

    func changeThemeTo(_ style: UIUserInterfaceStyle) {
        Defaults.appearance = style
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = style
        }
    }

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        // TODO: - Swizzle localization later
//        Bundle.swizzleLocalization()
        IntercomStartingConfigurator().configure()

        setupNavigationAppearance()

        FirebaseApp.configure()

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

        // set window
        window = UIWindow(frame: UIScreen.main.bounds)
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = Defaults.appearance
        }

        notificationService.wasAppLaunchedFromPush(launchOptions: launchOptions)

        // set rootVC
        let vm = Root.ViewModel()
        let vc = Root.ViewController(viewModel: vm)
        window?.rootViewController = vc
        window?.makeKeyAndVisible()

        setupRemoteConfig()

        return true
    }

    func application(
        _: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task.detached(priority: .background) { [unowned self] in
            await notificationService.sendRegisteredDeviceToken(deviceToken)
        }
    }

    func application(
        _: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        debugPrint("Failed to register: \(error)")
    }

    func application(
        _: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler _: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        notificationService.didReceivePush(userInfo: userInfo)
    }

    private func setupRemoteConfig() {
        #if DEBUG
            let settings = RemoteConfigSettings()
            // WARNING: Don't actually do this in production!
            settings.minimumFetchInterval = 0
            RemoteConfig.remoteConfig().configSettings = settings
        #endif
        let currentEndpoints = APIEndPoint.definedEndpoints
        FeatureFlagProvider.shared.fetchFeatureFlags(mainFetcher: RemoteConfig.remoteConfig()) { _ in
            let newEndpoints = APIEndPoint.definedEndpoints
            guard currentEndpoints != newEndpoints else { return }
            if !(newEndpoints.contains { $0 == Defaults.apiEndPoint }),
               let firstEndpoint = newEndpoints.first
            {
                Resolver.resolve(ChangeNetworkResponder.self).changeAPIEndpoint(to: firstEndpoint)
            }
        }
        Defaults.isCoingeckoProviderDisabled = !RemoteConfig.remoteConfig()
            .configValue(forKey: Feature.coinGeckoPriceProvider.rawValue).boolValue
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
