import UIKit

struct TipAppearance {
    let backgroundColor: UIColor
    let textColor: UIColor
    let countColor: UIColor
    let nextButtonStyle: TextButton.Style
    let skipButtonStyle: TextButton.Style
    let pointerMarginSide: UIEdgeInsets
    let pointerPosition: TipPointerPosition

    init(theme: TipTheme, pointerPosition: TipPointerPosition, pointerInset: CGFloat) {
        self.pointerPosition = pointerPosition

        switch theme {
        case .snow:
            backgroundColor = Asset.Colors.snow.color
            textColor = Asset.Colors.night.color
            nextButtonStyle = .third
            skipButtonStyle = .ghost
            countColor = Asset.Colors.mountain.color

        case .night:
            backgroundColor = Asset.Colors.night.color
            textColor = Asset.Colors.snow.color
            nextButtonStyle = .third
            skipButtonStyle = .ghostLime
            countColor = Asset.Colors.mountain.color

        case .lime:
            backgroundColor = Asset.Colors.lime.color
            textColor = Asset.Colors.night.color
            nextButtonStyle = .primary
            skipButtonStyle = .ghost
            countColor = Asset.Colors.mountain.color

        }

        switch pointerPosition {
        case .bottomRight, .bottomLeft, .bottomCenter:
            pointerMarginSide = UIEdgeInsets(only: .bottom, inset: pointerInset)
        case .topRight, .topLeft, .topCenter:
            pointerMarginSide = UIEdgeInsets(only: .top, inset: pointerInset)
        case .leftBottom, .leftTop, .leftCenter:
            pointerMarginSide = UIEdgeInsets(only: .left, inset: pointerInset)
        case .rightBottom, .rightTop, .rightCenter:
            pointerMarginSide = UIEdgeInsets(only: .right, inset: pointerInset)
        case .none:
            pointerMarginSide = .zero
        }
    }
}
