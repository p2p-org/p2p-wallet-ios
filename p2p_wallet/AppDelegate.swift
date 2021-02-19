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
import THPinViewController
import Action

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let container = DependencyContainer()
    
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
        
        // fetch prices
        PricesManager.shared.startObserving()
        
        // BEPureLayoutConfiguration
        BEPureLayoutConfigs.defaultBackgroundColor = .background
        BEPureLayoutConfigs.defaultTextColor = .textBlack
        BEPureLayoutConfigs.defaultNavigationBarColor = .textWhite
        BEPureLayoutConfigs.defaultNavigationBarTextFont = .systemFont(ofSize: 17, weight: .semibold)
        BEPureLayoutConfigs.defaultShadowColor = .textBlack
//        let image = UIImage.backButton.withRenderingMode(.alwaysOriginal)
//        BEPureLayoutConfigs.defaultBackButton = UIBarButtonItem(image: image, style: .plain, target: nil, action: nil)
        BEPureLayoutConfigs.defaultCheckBoxActiveColor = .textBlack
        
        // THPinViewController
        THPinInputCircleView.fillColor = .passcodeHighlightColor
        THPinNumButton.textColor = .textBlack
        THPinNumButton.textHighlightColor = .white
        THPinNumButton.backgroundHighlightColor = .passcodeHighlightColor
        
        // Use Firebase library to configure APIs
        FirebaseApp.configure()
        
        // set window
        window = UIWindow(frame: UIScreen.main.bounds)
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = Defaults.appearance
        }
        
        // set rootVC
        let vc = container.makeRootViewController()
        window?.rootViewController = vc
        
        window?.makeKeyAndVisible()
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        
    }
    
    fileprivate func showAuthentication() {
        let topVC = self.window?.rootViewController?.topViewController()
        let localAuthVC = DependencyContainer.shared.makeLocalAuthVC()
        localAuthVC.completion = { [self] didSuccess in
            localAuthVCShown = false
            if !didSuccess {
                topVC?.showErrorView()
                // reset timestamp
                timestamp = Date().timeIntervalSince1970
                
                Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                    topVC?.errorView?.descriptionLabel.text = L10n.authenticationFailed + "\n" + L10n.retryAfter + " \(Int(10 - Date().timeIntervalSince1970 + timestamp) + 1) " + L10n.seconds

                    if Int(Date().timeIntervalSince1970) == Int(timestamp + timeRequiredForAuthentication) {
                        topVC?.errorView?.descriptionLabel.text = L10n.tapButtonToRetry
                        topVC?.errorView?.buttonAction = CocoaAction {
                            showAuthentication()
                            return .just(())
                        }
                        timer.invalidate()
                    }
                }
            } else {
                topVC?.removeErrorView()
            }
        }
        localAuthVC.modalPresentationStyle = .fullScreen
        topVC?.present(localAuthVC, animated: true, completion: nil)
        localAuthVCShown = true
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
