// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import UIKit
import SwiftUI

extension TextButton {
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

        var backgroundColor: UIColor {
            switch self {
            case .primary, .primaryWhite: return UIColor(resource: .night)
            case .second: return UIColor(resource: .rain)
            case .third: return UIColor(resource: .lime)
            case .ghost, .ghostWhite, .ghostLime, .outlineBlack, .outlineWhite, .outlineLime, .outlineRose: return .clear
            case .inverted, .invertedRed: return UIColor(resource: .snow)
            }
        }

        var disabledBackgroundColor: UIColor? {
            switch self {
            case .ghost, .ghostWhite, .ghostLime, .outlineBlack, .outlineWhite, .outlineLime, .outlineRose: return .clear
            default: return UIColor(resource: .rain)
            }
        }

        var foreground: UIColor {
            switch self {
            case .primary, .ghostLime, .outlineLime: return UIColor(resource: .lime)
            case .primaryWhite, .ghostWhite, .outlineWhite: return UIColor(resource: .snow)
            case .second, .third, .ghost, .inverted, .outlineBlack: return UIColor(resource: .night)
            case .invertedRed, .outlineRose: return UIColor(resource: .rose)
            }
        }

        var disabledForegroundColor: UIColor? {
            UIColor(resource: .mountain)
        }

        var borderColor: UIColor? {
            switch self {
            case .outlineBlack: return UIColor(resource: .night)
            case .outlineWhite: return UIColor(resource: .snow)
            case .outlineLime: return UIColor(resource: .lime)
            case .outlineRose: return UIColor(resource: .rose)
            default: return nil
            }
        }

        func borderWidth(size: Size) -> CGFloat? {
            switch size {
            case .large, .medium: return 2
            case .small: return 1
            }
        }

        func font(size: Size) -> UIFont {
            switch size {
            case .large, .medium: return UIFont.font(of: .text2, weight: .bold)
            case .small: return UIFont.font(of: .text4, weight: .semibold)
            }
        }

        func font(size: Size) -> Font {
            switch size {
            case .large, .medium: return Font.system(size: UIFont.fontSize(of: .text2), weight: .bold)
            case .small: return Font.system(size: UIFont.fontSize(of: .text4), weight: .semibold)
            }
        }

        var highlight: UIColor {
            switch self {
            default: return .gray
            }
        }

        var loadingBackgroundColor: UIColor {
            switch self {
            case .primary, .primaryWhite, .ghostWhite, .ghostLime, .outlineWhite, .outlineLime: return UIColor(resource: .snow).withAlphaComponent(0.6)
            case .invertedRed, .outlineRose: return UIColor(resource: .rain)
            default: return UIColor(resource: .night).withAlphaComponent(0.6)
            }
        }

        var loadingForegroundColor: UIColor {
            switch self {
            case .primary, .ghostLime, .outlineLime: return UIColor(resource: .lime)
            case .primaryWhite, .ghostWhite, .outlineWhite: return UIColor(resource: .snow)
            case .second, .third, .ghost, .inverted, .outlineBlack: return UIColor(resource: .night)
            case .invertedRed, .outlineRose: return UIColor(resource: .rose)
            }
        }
    }

    enum Size: CaseIterable {
        case large
        case medium
        case small

        var height: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 48
            case .large: return 56
            }
        }

        var borderRadius: CGFloat {
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
