//
//  UIWindow+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import MBProgressHUD

extension UIWindow {
    func showIndetermineHudWithMessage(_ message: String?) {
        // Hide all previous hud
        hideHud()
        
        // show new hud
        let hud = MBProgressHUD.showAdded(to: self, animated: false)
        hud.mode = MBProgressHUDMode.indeterminate
        hud.isUserInteractionEnabled = true
        hud.label.text = message
    }
    
    func hideHud() {
        MBProgressHUD.hide(for: self, animated: false)
    }
}
