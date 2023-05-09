// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import UIKit

/// A appearance for ``IconButton``
public struct IconButtonAppearance {
    
    /// A tint color for icon. Icon should be rendered as template.
    let iconColor: UIColor
    
    /// A title color.
    let titleColor: UIColor
    
    /// A background color of button.
    let backgroundColor: UIColor
    
    /// A font of title.
    let font: UIFont
    
    /// A icon size.
    let iconSize: CGFloat
    
    /// A spacing between icon and title
    let titleSpacing: CGFloat
    
    /// A border radius of icon.
    let borderRadius: CGFloat

    /// A border color
    let borderColor: UIColor?

    public init(
        iconColor: UIColor,
        titleColor: UIColor,
        backgroundColor: UIColor,
        font: UIFont,
        iconSize: CGFloat,
        titleSpacing: CGFloat,
        borderRadius: CGFloat,
        borderColor: UIColor?
    ) {
        self.iconColor = iconColor
        self.titleColor = titleColor
        self.backgroundColor = backgroundColor
        self.font = font
        self.iconSize = iconSize
        self.titleSpacing = titleSpacing
        self.borderRadius = borderRadius
        self.borderColor = borderColor
    }

    /// Default appearance
    public static func `default`() -> Self {
        .init(
            iconColor: Asset.Colors.lime.color,
            titleColor: Asset.Colors.night.color,
            backgroundColor: Asset.Colors.night.color,
            font: .systemFont(ofSize: 16, weight: .medium),
            iconSize: 40,
            titleSpacing: 8,
            borderRadius: 20,
            borderColor: nil
        )
    }

    /// Create a new appearance with new value.
    func copy(
        iconColor: UIColor? = nil,
        backgroundColor: UIColor? = nil
    ) -> Self {
        .init(
            iconColor: iconColor ?? self.iconColor,
            titleColor: titleColor,
            backgroundColor: backgroundColor ?? self.backgroundColor,
            font: font,
            iconSize: iconSize,
            titleSpacing: titleSpacing,
            borderRadius: borderRadius,
            borderColor: borderColor
        )
    }
}
