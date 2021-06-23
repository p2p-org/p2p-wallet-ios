//
//  UIView+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation
import Action

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
        subviews.filter {$0 is ErrorView}.forEach {$0.removeFromSuperview()}
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
    
    // MARK: - View builders
    static func squareRoundedCornerIcon(
        backgroundColor: UIColor = .grayPanel,
        imageSize: CGFloat = 24,
        image: UIImage?,
        tintColor: UIColor = .iconSecondary,
        padding: UIEdgeInsets = .init(all: 12.25),
        cornerRadius: CGFloat = 12
    ) -> UIView {
        UIImageView(width: imageSize, height: imageSize, image: image, tintColor: tintColor)
            .padding(padding, backgroundColor: backgroundColor, cornerRadius: 12)
    }
    
    static func allDepositsAreStored100NonCustodiallityWithKeysHeldOnThisDevice(
    ) -> UIStackView {
        UIStackView(axis: .horizontal, spacing: 12, alignment: .center, distribution: .fill) {
            UIImageView(width: 20, height: 20, image: .lock, tintColor: .iconSecondary)
            
            UILabel(
                text: L10n
                    .allDepositsAreStored100NonCustodiallityWithKeysHeldOnThisDevice,
                textSize: 13,
                weight: .medium,
                textColor: .iconSecondary,
                numberOfLines: 0
            )
        }
    }
}
