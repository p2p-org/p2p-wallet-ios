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
    
    func removeErrorView() {
        subviews.filter {$0 is ErrorView}.forEach {$0.removeFromSuperview()}
    }
    
    func showErrorView(title: String? = nil, description: String? = nil) {
        removeErrorView()
        let errorView = ErrorView(backgroundColor: .textWhite)
        if let title = title {
            errorView.titleLabel.text = title
        }
        if let description = description {
            errorView.descriptionLabel.text = description
        }
        let spacer1 = UIView.spacer
        let spacer2 = UIView.spacer
        errorView.stackView.insertArrangedSubview(spacer1, at: 0)
        errorView.stackView.addArrangedSubview(spacer2)
        spacer1.heightAnchor.constraint(equalTo: spacer2.heightAnchor).isActive = true
        addSubview(errorView)
        errorView.autoPinEdgesToSuperviewEdges()
    }
    
    func showErrorView(error: Error) {
        let description = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        showErrorView(title: L10n.error, description: description)
    }
}
