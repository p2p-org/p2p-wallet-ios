//
//  AppDelegate.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/22/20.
//

import UIKit
@_exported import BEPureLayout
@_exported import SolanaSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        #if DEBUG
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
        if APIManager.keychainStorage.account == nil {
            rootVC = WelcomeVC()
        } else {
            rootVC = BENavigationController(rootViewController: PinCodeVC())
        }
        
        self.window?.rootViewController = rootVC
        self.window?.makeKeyAndVisible()
        return true
    }

}
