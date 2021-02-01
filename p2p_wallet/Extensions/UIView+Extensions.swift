//
//  UIView+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation
import MBProgressHUD

extension UIView {
    func fittingHeight(targetWidth: CGFloat) -> CGFloat {
        let fittingSize = CGSize(
            width: targetWidth,
            height: UIView.layoutFittingCompressedSize.height
        )
        return systemLayoutSizeFitting(fittingSize, withHorizontalFittingPriority: .required,
                                verticalFittingPriority: .defaultLow)
            .height
    }
    
    static func copyToClipboardButton(spacing: CGFloat = 10, tintColor: UIColor = .textSecondary) -> UIStackView {
        UIStackView(axis: .horizontal, spacing: spacing, alignment: .center, distribution: .fill, arrangedSubviews: [
            UIImageView(width: 24, height: 24, image: .copyToClipboard, tintColor: tintColor),
            UILabel(text: L10n.copyToClipboard, weight: .medium, textColor: tintColor)
        ])
    }
    
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
