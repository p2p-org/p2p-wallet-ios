import UIKit

public extension SliderButton {
    enum Style: CaseIterable {
        case white
        case black
        case solidBlack

        var backgroundColor: UIColor {
            switch self {
            case .white: return Asset.Colors.snow.color
            case .black, .solidBlack: return Asset.Colors.night.color
            }
        }

        var iconColor: UIColor {
            switch self {
            case .white: return Asset.Colors.lime.color
            case .black, .solidBlack: return Asset.Colors.night.color
            }
        }

        var iconBackgroundColor: UIColor {
            switch self {
            case .white: return Asset.Colors.night.color
            case .black, .solidBlack: return Asset.Colors.lime.color
            }
        }

        var titleColor: UIColor {
            switch self {
            case .white: return Asset.Colors.night.color
            case .black, .solidBlack: return Asset.Colors.snow.color
            }
        }

        var progressColor: UIColor? {
            switch self {
            case .white, .black: return nil
            case .solidBlack: return Asset.Colors.night.color
            }
        }

        func font() -> UIFont {
            UIFont.font(of: .text2, weight: .semibold)
        }
    }

    convenience init(image: UIImage, title: String? = nil, style: Style) {
        let theme = SliderButtonAppearance(
            backgroundColor: style.backgroundColor,
            titleColor: style.titleColor,
            font: style.font(),
            iconColor: style.iconColor,
            iconBackgroundColor: style.iconBackgroundColor,
            isGradient: style != .solidBlack,
            progressColor: style.progressColor
        )

        self.init(
            image: image,
            title: title,
            theme: theme
        )
    }
}
