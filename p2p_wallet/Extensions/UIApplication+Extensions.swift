//
//  UIApplication+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation
import MBProgressHUD

extension UIApplication {
    func changeRootVC(to rootVC: UIViewController, withNaviationController: Bool = false) {
        guard let window = keyWindow else {
            return
        }
        window.rootViewController = withNaviationController ? BENavigationController(rootViewController: rootVC) : rootVC
        
        UIView.transition(with: window, duration: 0.3, options: .transitionFlipFromLeft, animations: {})
    }
    
    func showIndetermineHudWithMessage(_ message: String?) {
        guard let keyWindow = keyWindow else {return}
        
        // Hide all previous hud
        hideHud()
        
        // show new hud
        let hud = MBProgressHUD.showAdded(to: keyWindow, animated: false)
        hud.mode = MBProgressHUDMode.indeterminate
        hud.isUserInteractionEnabled = true
        hud.label.text = message
    }
    
    func hideHud() {
        guard let keyWindow = keyWindow else {return}
        MBProgressHUD.hide(for: keyWindow, animated: false)
    }
    
    func showDone(_ message: String, completion: (() -> Void)? = nil) {
        guard let keyWindow = keyWindow else {return}
        
        // Hide all previous hud
        hideHud()
        
        // show new hud
        let hud = MBProgressHUD.showAdded(to: keyWindow, animated: false)
        hud.mode = .customView
        let imageView = UIImageView(width: 100, height: 100, image: .checkMark)
        imageView.tintColor = .textBlack
        hud.customView = imageView
        hud.label.text = message
        hud.hide(animated: true, afterDelay: 1)
        if let completion = completion {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: completion)
        }
    }
    
    func openAppSettings() {
        if let bundleIdentifier = Bundle.main.bundleIdentifier, let appSettings = URL(string: UIApplication.openSettingsURLString + bundleIdentifier) {
            if canOpenURL(appSettings) {
                open(appSettings)
            }
        }
    }
}
