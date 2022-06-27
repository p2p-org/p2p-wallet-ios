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
