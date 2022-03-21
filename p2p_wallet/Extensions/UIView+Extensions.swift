//
//  UIView+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Action
import Foundation

extension UIView {
    static func copyToClipboardButton(spacing: CGFloat = 10, tintColor: UIColor = .textSecondary) -> UIStackView {
        UIStackView(axis: .horizontal, spacing: spacing, alignment: .center, distribution: .fill, arrangedSubviews: [
            UIImageView(width: 24, height: 24, image: .copyToClipboard, tintColor: tintColor),
            UILabel(text: L10n.copyToClipboard, weight: .medium, textColor: tintColor),
        ])
    }

    func showIndetermineHud() {
        // Hide all previous hud
        hideHud()

        // show new hud
        showLoadingIndicatorView()
    }

    func hideHud() {
        hideLoadingIndicatorView()
    }

    func removeErrorView() {
        subviews.filter {
            $0 is ErrorView
        }.forEach {
            $0.removeFromSuperview()
        }
    }

    func showErrorView(title: String? = nil, description: String? = nil, retryAction: CocoaAction? = nil) {
        removeErrorView()
        let errorView = ErrorView(backgroundColor: .textWhite)
        if let title = title {
            errorView.titleLabel.text = title
        }
        if let description = description {
            errorView.descriptionLabel.text = description
        }
        if let action = retryAction {
            errorView.buttonAction = action
        }
        let spacer1 = UIView.spacer
        let spacer2 = UIView.spacer
        errorView.stackView.insertArrangedSubview(spacer1, at: 0)
        errorView.stackView.addArrangedSubview(spacer2)
        spacer1.heightAnchor.constraint(equalTo: spacer2.heightAnchor).isActive = true
        addSubview(errorView)
        errorView.autoPinEdgesToSuperviewEdges()
    }

    func showErrorView(error: Error?, retryAction: CocoaAction? = nil) {
        showErrorView(title: L10n.error, description: error?.readableDescription ?? L10n.somethingWentWrongPleaseTryAgainLater, retryAction: retryAction)
    }
}

extension UIView {
    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }

    func asImageInBackground() -> UIImage {
        layoutIfNeeded()
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

extension UIView {
    func lightShadow() -> Self {
        shadow(color: .black, alpha: 0.05, x: 0, y: 0, blur: 8, spread: 0)
    }

    func mediumShadow() -> Self {
        shadow(color: .black, alpha: 0.07, x: 0, y: 2, blur: 8, spread: 0)
    }
}
