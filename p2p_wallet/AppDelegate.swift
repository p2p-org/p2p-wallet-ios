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
import TrustKit
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
        // TODO: Needs a remote to config to turn off remotely if something goes wrong
        configureSSLPinning()
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
//        #if DEBUG
//        #else
        FirebaseApp.configure()
//        #endif

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

    // MARK: - SSL Pinning

    func configureSSLPinning() {
        let trustKitConfig = [
            kTSKEnforcePinning: true,
            kTSKSwizzleNetworkDelegates: true,
            kTSKPinnedDomains: [
                "p2p.rpcpool.com": [
                    kTSKPublicKeyHashes: [
                        "4tENtRMJ8xlPlTvOnNPsoJoaZYs6NvKIB+2RvjHTV5c=",
                        // Needs to add an additional pubkey
                        "1tENtRMJ8xlPlTvOnNPsoJoaZYs6NvKIB+2RvjHTV5c=",
                    ],
                ],
                "fee-relayer.solana.p2p.org": [
                    kTSKPublicKeyHashes: [
                        "2WYrJfkTWXCoYZl/g65hBQ6Xy27KxhDQyyQgS1JWxDI=",
                        // Needs to add an additional pubkey
                        "1WYrJfkTWXCoYZl/g65hBQ6Xy27KxhDQyyQgS1JWxDI=",
                    ],
                ],
            ],
        ] as [String: Any]

        TrustKit.initSharedInstance(withConfiguration: trustKitConfig)
    }
}
