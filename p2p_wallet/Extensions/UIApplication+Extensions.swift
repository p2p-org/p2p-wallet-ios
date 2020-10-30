//
//  UIApplication+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation
import MBProgressHUD

extension UIApplication {
    func changeRootVC(to rootVC: UIViewController) {
        keyWindow?.rootViewController = rootVC
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
}
