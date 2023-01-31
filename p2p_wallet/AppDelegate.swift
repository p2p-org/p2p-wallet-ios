//
//  AppDelegate.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/22/20.
//

@_exported import BEPureLayout
import FeeRelayerSwift
import Firebase
import Intercom
import KeyAppKitLogger
import KeyAppUI
import Lokalise
import Resolver
import Sentry
import SolanaSwift
@_exported import SwiftyUserDefaults
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var appCoordinator: AppCoordinator?
    static var shared: AppDelegate {
        UIApplication.shared.delegate as! AppDelegate
    }

    private lazy var proxyAppDelegate = AppDelegateProxyService()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Force setup

        // TODO: - Support custom fiat later
        Defaults.fiat = .usd
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        setupNavigationAppearance()

        guard proxyAppDelegate.application(application, didFinishLaunchingWithOptions: launchOptions) == true else {
            return false
        }

        // Set app coordinator
        appCoordinator = AppCoordinator()
        appCoordinator!.start()
        window = appCoordinator?.window

        UIViewController.swizzleViewDidDisappear()
        UIViewController.swizzleViewDidAppear()

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        proxyAppDelegate.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        Defaults.apnsDeviceToken = deviceToken
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

    func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return proxyAppDelegate.application(application, open: url, options: options)
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        return proxyAppDelegate.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        proxyAppDelegate.application(
            application,
            didReceiveRemoteNotification: userInfo,
            fetchCompletionHandler: completionHandler
        )
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        proxyAppDelegate.applicationDidBecomeActive(application)
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
}
