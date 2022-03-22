//
//  UIApplication+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation

extension UIApplication {
    var kWindow: UIWindow? {
        // keyWindow is deprecated
        UIApplication.shared.windows.first { $0.isKeyWindow }
    }

    func showIndetermineHud() {
        kWindow?.showIndetermineHud()
    }

    func hideHud() {
        kWindow?.hideHud()
    }

    func openAppSettings() {
        if let bundleIdentifier = Bundle.main.bundleIdentifier,
           let appSettings = URL(string: UIApplication.openSettingsURLString + bundleIdentifier)
        {
            if canOpenURL(appSettings) {
                open(appSettings)
            }
        }
    }
}
