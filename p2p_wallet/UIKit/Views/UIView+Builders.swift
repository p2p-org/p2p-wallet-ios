//
//  UIView+Builders.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/11/2021.
//

import BEPureLayout
import KeyAppUI
import SwiftUI
import UIKit

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
            iconView = UIImageView(height: 349.adaptiveHeight, image: image)
            iconView!.autoAdjustWidthHeightRatio(image.size.width / image.size.height)
        }

        if let iconView = iconView {
            stackView.addArrangedSubview(iconView.centered(.horizontal))
        }

        stackView.addArrangedSubview(
            UILabel(text: title, textSize: 34.adaptiveHeight, weight: .bold, numberOfLines: 0, textAlignment: .center)
                .withContentHuggingPriority(.required, for: .vertical)
        )

        if let description = description {
            stackView.addArrangedSubview(
                UILabel(
                    text: description,
                    textSize: 17.adaptiveHeight,
                    weight: .medium,
                    numberOfLines: 0,
                    textAlignment: .center
                )
                    .withContentHuggingPriority(.required, for: .vertical)
            )
        }

        return stackView
            .withContentHuggingPriority(.required, for: .vertical)
            .centered(.vertical)
    }

    /// PatternView with lines
    static func introPatternView() -> UIImageView {
        UIImageView(image: .introPatternBg, tintColor: .textSecondary.withAlphaComponent(0.05))
    }

    /// Grey banner
    static func greyBannerView(
        contentInset: UIEdgeInsets = .init(all: 18),
        axis: NSLayoutConstraint.Axis = .vertical,
        spacing: CGFloat = 8,
        alignment: UIStackView.Alignment = .fill,
        distribution: UIStackView.Distribution = .fill,
        @BEStackViewBuilder builder: () -> [BEStackViewElement]
    ) -> UIView {
        UIStackView(axis: axis, spacing: spacing, alignment: alignment, distribution: distribution, builder: builder)
            .padding(contentInset, backgroundColor: .a3a5ba.withAlphaComponent(0.05), cornerRadius: 12)
    }

    static func greenBannerView(
        contentInset: UIEdgeInsets = .init(all: 18),
        axis: NSLayoutConstraint.Axis = .vertical,
        spacing: CGFloat = 8,
        alignment: UIStackView.Alignment = .fill,
        distribution: UIStackView.Distribution = .fill,
        @BEStackViewBuilder builder: () -> [BEStackViewElement]
    ) -> UIView {
        UIStackView(axis: axis, spacing: spacing, alignment: alignment, distribution: distribution, builder: builder)
            .padding(contentInset, backgroundColor: .f5fcf7, cornerRadius: 12, borderColor: .h34c759)
    }

    static func squareRoundedCornerIcon(
        backgroundColor: UIColor = .grayPanel,
        imageSize: CGFloat = 24,
        image: UIImage?,
        tintColor: UIColor = .iconSecondary,
        padding: UIEdgeInsets = .init(all: 12.25),
        cornerRadius _: CGFloat = 12
    ) -> UIView {
        UIImageView(width: imageSize, height: imageSize, image: image, tintColor: tintColor)
            .padding(padding, backgroundColor: backgroundColor, cornerRadius: 12)
    }

    static func defaultSeparator(height: CGFloat = 1) -> UIView {
        .separator(height: height, color: .separator)
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

    static func closeBannerButton() -> UIImageView {
        UIImageView(width: 24, height: 24, image: .closeBanner, tintColor: Asset.Colors.night.color)
    }
}
