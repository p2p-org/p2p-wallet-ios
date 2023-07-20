// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import UIKit

public extension IconButton {
    /// A predefined styles
    ///
    /// ![Conver](IconButtonStyle.png)
    enum Style: CaseIterable {
        case primary
        case primaryWhite
        case second
        case third
        case ghostBlack
        case ghostWhite
        case ghostLime
        case inverted
        case outlineBlack
        case outlineWhite
        case outlineLime
        case outlineRose

        var backgroundColor: UIColor {
            switch self {
            case .primary, .primaryWhite: return Asset.Colors.night.color
            case .second: return Asset.Colors.rain.color
            case .third: return Asset.Colors.lime.color
            case .ghostBlack, .ghostWhite, .ghostLime, .outlineBlack, .outlineWhite, .outlineLime, .outlineRose: return .clear
            case .inverted: return Asset.Colors.snow.color
            }
        }

        var disabledBackgroundColor: UIColor? {
            Asset.Colors.rain.color
        }

        var iconColor: UIColor {
            switch self {
            case .primary, .ghostLime, .outlineLime: return Asset.Colors.lime.color
            case .primaryWhite, .ghostWhite, .outlineWhite: return Asset.Colors.snow.color
            case .second, .third, .ghostBlack, .inverted, .outlineBlack: return Asset.Colors.night.color
            case .outlineRose: return Asset.Colors.rose.color
            }
        }

        var borderColor: UIColor? {
            switch self {
            case .outlineBlack: return Asset.Colors.night.color
            case .outlineWhite: return Asset.Colors.snow.color
            case .outlineLime: return Asset.Colors.lime.color
            case .outlineRose: return Asset.Colors.rose.color
            default: return nil
            }
        }

        var titleColor: UIColor {
            switch self {
            case .primary, .primaryWhite, .second, .third, .ghostBlack, .inverted, .outlineBlack: return Asset.Colors.night.color
            case .ghostWhite, .outlineWhite: return Asset.Colors.snow.color
            case .ghostLime, .outlineLime: return Asset.Colors.lime.color
            case .outlineRose: return Asset.Colors.rose.color
            }
        }

        var disabledIconColor: UIColor? {
            Asset.Colors.mountain.color
        }

        func font(size: Size) -> UIFont {
            UIFont.font(of: .label2, weight: .regular)
        }

        var highlight: UIColor {
            switch self {
            default: return .gray
            }
        }
    }

    enum Size: CaseIterable {
        case large
        case medium
        case small

        var width: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 52
            case .large: return 80
            }
        }

        var borderRadius: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 20
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 20
            case .large: return 32
            }
        }

        var titleSpacing: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 4
            case .large: return 8
            }
        }
    }

    /// Create button with defined style
    convenience init(image: UIImage, title: String? = nil, style: Style, size: Size) {
        let theme: IconButtonAppearance = .init(
            iconColor: style.iconColor,
            titleColor: style.titleColor,
            backgroundColor: style.backgroundColor,
            font: style.font(size: size),
            iconSize: size.iconSize,
            titleSpacing: size.titleSpacing,
            borderRadius: size.borderRadius,
            borderColor: style.borderColor
        )

        self.init(
            image: image,
            title: title,
            themes: [
                .normal: theme,
                .disabled: theme.copy(
                    iconColor: style.disabledIconColor,
                    backgroundColor: style.disabledBackgroundColor
                ),
                .highlighted: theme.copy(backgroundColor: style.highlight),
            ]
        )
        let _ = frame(width: size.width)
    }
}
