//
//  AppDelegate.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/22/20.
//

import UIKit
@_exported import BEPureLayout
@_exported import SolanaSwift
@_exported import SwiftyUserDefaults

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        #if DEBUG
//        KeychainStorage.shared.clear()
        
        Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle")!.load()
//        //for tvOS:
//        Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/tvOSInjection.bundle")?.load()
//        //Or for macOS:
//        Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/macOSInjection.bundle")?.load()
        #endif
        
        // BEPureLayoutConfiguration
        BEPureLayoutConfigs.defaultTextColor = .textBlack
        BEPureLayoutConfigs.defaultNavigationBarColor = .background
        BEPureLayoutConfigs.defaultNavigationBarTextFont = .systemFont(ofSize: 17, weight: .semibold)
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        
        let rootVC: UIViewController
        if KeychainStorage.shared.account == nil {
            rootVC = WelcomeVC()
        } else {
            if KeychainStorage.shared.pinCode == nil {
                rootVC = BENavigationController(rootViewController: SSPinCodeVC())
            } else if !Defaults.didSetEnableBiometry {
                rootVC = BENavigationController(rootViewController: EnableBiometryVC())
            } else if !Defaults.didSetEnableNotifications {
                rootVC = BENavigationController(rootViewController: EnableNotificationsVC())
            } else {
                rootVC = BaseVC()
            }
        }
        
        self.window?.rootViewController = rootVC
        self.window?.makeKeyAndVisible()
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register: \(error)")
    }
}
