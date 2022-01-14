//
//  AppDelegate.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/22/20.
//

import UIKit
import Firebase
@_exported import BEPureLayout
@_exported import SolanaSwift
@_exported import SwiftyUserDefaults
@_exported import Resolver
import Action
import BECollectionView

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    static var shared: AppDelegate {
        UIApplication.shared.delegate as! AppDelegate
    }
    
    func changeThemeTo(_ style: UIUserInterfaceStyle) {
        Defaults.appearance = style
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = style
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        Bundle.swizzleLocalization()
        
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
        #if DEBUG
        #else
        FirebaseApp.configure()
        #endif
        
        // set window
        window = UIWindow(frame: UIScreen.main.bounds)
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = Defaults.appearance
        }
        
        // set rootVC
        let vm = Root.ViewModel()
        let vc = Root.ViewController(viewModel: vm)
        window?.rootViewController = vc
        
        window?.makeKeyAndVisible()
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        
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
