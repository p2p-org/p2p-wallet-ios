//
//  UIView+Builders.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/11/2021.
//

import Foundation

extension UIView {
    /// Create a stackview that have an image (or a custom view) followed by a title and a description
    /// - Parameters:
    ///   - image: image on top
    ///   - title: title
    ///   - description: description
    ///   - customView: (optional) custom view, if defined, the image will be ignored
    /// - Returns: stackview which is adaptive on large and small screens
    static func ilustrationView(
        image: UIImage? = nil,
        title: String,
        description: String? = nil,
        replacingImageWithCustomView customView: UIView? = nil
    ) -> UIView {
        let stackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill)
        
        var iconView: UIView?
        if let customView = customView {
            iconView = customView
        } else if let image = image {
            iconView = UIImageView(image: image)
            iconView!.autoAdjustWidthHeightRatio(image.size.width/image.size.height)
        }
        
        if let iconView = iconView {
            stackView.addArrangedSubview(iconView.centered(.horizontal))
        }
        
        stackView.addArrangedSubview(
            UILabel(text: title, textSize: 34.adaptiveHeight, weight: .bold, numberOfLines: 2, textAlignment: .center)
                .withContentHuggingPriority(.required, for: .vertical)
        )
        
        if let description = description {
            stackView.addArrangedSubview(
                UILabel(text: description, textSize: 17.adaptiveHeight, weight: .medium, numberOfLines: 2, textAlignment: .center)
                    .withContentHuggingPriority(.required, for: .vertical)
            )
        }
        
        return stackView
            .withContentHuggingPriority(.required, for: .vertical)
            .centered(.vertical)
    }
}
