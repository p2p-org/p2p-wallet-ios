import UIKit

extension SliderButton {
    enum Style: CaseIterable {
        case white
        case black
        case solidBlack

        var backgroundColor: UIColor {
            switch self {
            case .white: return UIColor(resource: .snow)
            case .black, .solidBlack: return UIColor(resource: .night)
            }
        }

        var iconColor: UIColor {
            switch self {
            case .white: return UIColor(resource: .lime)
            case .black, .solidBlack: return UIColor(resource: .night)
            }
        }

        var iconBackgroundColor: UIColor {
            switch self {
            case .white: return UIColor(resource: .night)
            case .black, .solidBlack: return UIColor(resource: .lime)
            }
        }

        var titleColor: UIColor {
            switch self {
            case .white: return UIColor(resource: .night)
            case .black, .solidBlack: return UIColor(resource: .snow)
            }
        }

        var progressColor: UIColor? {
            switch self {
            case .white, .black: return nil
            case .solidBlack: return UIColor(resource: .night)
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
