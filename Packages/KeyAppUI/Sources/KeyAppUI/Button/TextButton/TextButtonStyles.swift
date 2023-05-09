// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import UIKit

public extension TextButton {
    enum Style: CaseIterable {
        case primary
        case primaryWhite
        case second
        case third
        case ghost
        case ghostWhite
        case ghostLime
        case inverted
        case invertedRed
        case outlineBlack
        case outlineWhite
        case outlineLime
        case outlineRose

        public var backgroundColor: UIColor {
            switch self {
            case .primary, .primaryWhite: return Asset.Colors.night.color
            case .second: return Asset.Colors.rain.color
            case .third: return Asset.Colors.lime.color
            case .ghost, .ghostWhite, .ghostLime, .outlineBlack, .outlineWhite, .outlineLime, .outlineRose: return .clear
            case .inverted, .invertedRed: return Asset.Colors.snow.color
            }
        }

        public var disabledBackgroundColor: UIColor? {
            switch self {
            case .ghost, .ghostWhite, .ghostLime, .outlineBlack, .outlineWhite, .outlineLime, .outlineRose: return .clear
            default: return Asset.Colors.rain.color
            }
        }

        public var foreground: UIColor {
            switch self {
            case .primary, .ghostLime, .outlineLime: return Asset.Colors.lime.color
            case .primaryWhite, .ghostWhite, .outlineWhite: return Asset.Colors.snow.color
            case .second, .third, .ghost, .inverted, .outlineBlack: return Asset.Colors.night.color
            case .invertedRed, .outlineRose: return Asset.Colors.rose.color
            }
        }

        public var disabledForegroundColor: UIColor? {
            Asset.Colors.mountain.color
        }

        public var borderColor: UIColor? {
            switch self {
            case .outlineBlack: return Asset.Colors.night.color
            case .outlineWhite: return Asset.Colors.snow.color
            case .outlineLime: return Asset.Colors.lime.color
            case .outlineRose: return Asset.Colors.rose.color
            default: return nil
            }
        }

        public func font(size: Size) -> UIFont {
            switch size {
            case .large, .medium: return UIFont.font(of: .text2, weight: .bold)
            case .small: return UIFont.font(of: .text4, weight: .semibold)
            }
        }

        public var highlight: UIColor {
            switch self {
            default: return .gray
            }
        }

        public var loadingBackgroundColor: UIColor {
            switch self {
            case .primary, .primaryWhite, .ghostWhite, .ghostLime, .outlineWhite, .outlineLime: return Asset.Colors.snow.color.withAlphaComponent(0.6)
            case .invertedRed, .outlineRose: return Asset.Colors.rain.color
            default: return Asset.Colors.night.color.withAlphaComponent(0.6)
            }
        }

        public var loadingForegroundColor: UIColor {
            switch self {
            case .primary, .ghostLime, .outlineLime: return Asset.Colors.lime.color
            case .primaryWhite, .ghostWhite, .outlineWhite: return Asset.Colors.snow.color
            case .second, .third, .ghost, .inverted, .outlineBlack: return Asset.Colors.night.color
            case .invertedRed, .outlineRose: return Asset.Colors.rose.color
            }
        }
    }

    enum Size: CaseIterable {
        case large
        case medium
        case small

        public var height: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 48
            case .large: return 56
            }
        }

        public var borderRadius: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 12
            }
        }
    }

    /// Create button with defined style
    convenience init(title: String, style: Style, size: Size, leading: UIImage? = nil, trailing: UIImage? = nil) {
        var left: CGFloat = leading != nil ? 14 : 20
        var right: CGFloat = trailing != nil ? 14 : 20
        
        if size == .small {
            left = 0
            right = 0
        }
        
        let theme = TextButtonAppearance(
            backgroundColor: style.backgroundColor,
            foregroundColor: style.foreground,
            font: style.font(size: size),
            contentPadding: .init(
                top: 0,
                left: left,
                bottom: 0,
                right: right
            ),
            iconSpacing: 8,
            borderRadius: size.borderRadius,
            loadingBackgroundColor: style.loadingBackgroundColor,
            loadingForegroundColor: style.loadingForegroundColor,
            borderColor: style.borderColor
        )
        self.init(
            leadingImage: leading,
            title: title,
            trailingImage: trailing,
            themes: [
                .normal: theme,
                .disabled: theme.copy(
                    backgroundColor: style.disabledBackgroundColor,
                    foregroundColor: style.disabledForegroundColor
                ),
                .highlighted: theme.copy(backgroundColor: style.highlight),
            ]
        )
        _ = frame(height: size.height)
    }
}
