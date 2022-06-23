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
@_exported import Resolver
@_exported import SolanaSwift
@_exported import SwiftyUserDefaults
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    @Injected private var notificationService: NotificationService
    @Injected private var changeNetworkResponder: ChangeNetworkResponder

    static var shared: AppDelegate {
        UIApplication.shared.delegate as! AppDelegate
    }

    private lazy var proxyAppDelegate = AppDelegateProxyService()

    func changeThemeTo(_ style: UIUserInterfaceStyle) {
        Defaults.appearance = style
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = style
        }
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        // TODO: - Swizzle localization later
//        Bundle.swizzleLocalization()
        IntercomStartingConfigurator().configure()

        // BEPureLayoutConfiguration
        BEPureLayoutConfigs.defaultBackgroundColor = .background
        BEPureLayoutConfigs.defaultTextColor = .textBlack
        BEPureLayoutConfigs.defaultNavigationBarColor = .textWhite
        BEPureLayoutConfigs.defaultNavigationBarTextFont = .systemFont(ofSize: 17, weight: .semibold)
        BEPureLayoutConfigs.defaultShadowColor = .textBlack
//        let image = UIImage.backButton.withRenderingMode(.alwaysOriginal)
//        BEPureLayoutConfigs.defaultBackButton = UIBarButtonItem(image: image, style: .plain, target: nil, action: nil)
        BEPureLayoutConfigs.defaultCheckBoxActiveColor = .h5887ff

        // Use Firebase library to configure APIs
        FirebaseApp.configure()

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

        setupDefaultFlags()
        FeatureFlagProvider.shared.fetchFeatureFlags(mainFetcher: defaultFlags)
        setupRemoteConfig()

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
        //        #if DEBUG
        let settings = RemoteConfigSettings()
        // WARNING: Don't actually do this in production!
        settings.minimumFetchInterval = 0
        RemoteConfig.remoteConfig().configSettings = settings
        //        #endif

        let currentEndpoints = SolanaSDK.APIEndPoint.definedEndpoints
        #if DEBUG
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
    }

    private func changeEndpointIfNeeded(currentEndpoints: [SolanaSDK.APIEndPoint]) {
        let newEndpoints = SolanaSDK.APIEndPoint.definedEndpoints
        guard currentEndpoints != newEndpoints else { return }
        if !(newEndpoints.contains { $0 == Defaults.apiEndPoint }),
           let firstEndpoint = newEndpoints.first
        {
            changeNetworkResponder.changeAPIEndpoint(to: firstEndpoint)
        }
    }
}
