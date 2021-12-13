//
//  UIView+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation
import Action

extension UIView {
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
    
    static func defaultSeparator(height: CGFloat = 1) -> UIView {
        .separator(height: height, color: .separator)
    }
    
    static func createSectionView(
        title: String? = nil,
        label: UIView? = nil,
        contentView: UIView,
        rightView: UIView? = .defaultNextArrow().padding(.init(x: 9 - 2.5, y: 6 - 2.5)),
        addSeparatorOnTop: Bool = true
    ) -> UIStackView {
        let stackView = UIStackView(axis: .horizontal, spacing: 5, alignment: .center, distribution: .fill) {
            UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill) {
                label ?? UILabel(
                    text: title,
                    textSize: 13,
                    weight: .medium,
                    textColor: .textSecondary
                )
                contentView
            }
        }
        
        if let rightView = rightView {
            stackView.addArrangedSubview(rightView)
        }
        
        if !addSeparatorOnTop {
            return stackView
        } else {
            return UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill) {
                UIView.defaultSeparator()
                stackView
            }
        }
    }
    
    static func switchField(text: String, switch switcher: UISwitch) -> UIView {
        let view = UIView(forAutoLayout: ())
        
        let label = UILabel(text: text, textSize: 15, weight: .semibold, numberOfLines: 0)
        view.addSubview(label)
        label.autoPinEdgesToSuperviewEdges(with: .init(top: 0, left: 0, bottom: 0, right: 51))
        
        view.addSubview(switcher)
        switcher.autoAlignAxis(.horizontal, toSameAxisOf: label)
        switcher.autoPinEdge(toSuperviewEdge: .trailing)
        
        return view
            .padding(.init(all: 20), cornerRadius: 12)
            .border(width: 1, color: .defaultBorder)
    }
    
    static func defaultNextArrow() -> UIView {
        // swiftlint:disable next_arrow
        UIImageView(
            width: 9,
            height: 16,
            image: .nextArrow,
            tintColor: .h8b94a9.onDarkMode(.white)
        )
            .padding(.init(all: 2.5))
        // swiftlint:enable next_arrow
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
}
