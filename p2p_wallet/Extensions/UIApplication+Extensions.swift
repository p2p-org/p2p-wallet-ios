//
//  UIApplication+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation
import MBProgressHUD

extension UIApplication {
    private var kWindow: UIWindow? {
        // keyWindow is deprecated
        UIApplication.shared.windows.first { $0.isKeyWindow }
    }
    
    func showIndetermineHud() {
        kWindow?.showIndetermineHud()
    }
    
    func hideHud() {
        kWindow?.hideHud()
    }
    
    func showLoadingIndicatorView(isBlocking: Bool = true) {
        kWindow?.showLoadingIndicatorView(isBlocking: isBlocking)
    }
    
    func hideLoadingIndicatorView() {
        kWindow?.hideLoadingIndicatorView()
    }
    
    func showDone(_ message: String, completion: (() -> Void)? = nil) {
        guard let keyWindow = kWindow else {return}
        
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
    
    func copyToClipboard(_ text: String?, alert: Bool = true) {
        UIPasteboard.general.string = text
        if alert {
            showDone(L10n.copiedToClipboard)
        }
    }
}
