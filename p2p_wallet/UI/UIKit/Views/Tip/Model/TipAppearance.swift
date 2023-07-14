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
            backgroundColor = UIColor(resource: .snow)
            textColor = UIColor(resource: .night)
            nextButtonStyle = .third
            skipButtonStyle = .ghost
            countColor = UIColor(resource: .mountain)

        case .night:
            backgroundColor = UIColor(resource: .night)
            textColor = UIColor(resource: .snow)
            nextButtonStyle = .third
            skipButtonStyle = .ghostLime
            countColor = UIColor(resource: .mountain)

        case .lime:
            backgroundColor = UIColor(resource: .lime)
            textColor = UIColor(resource: .night)
            nextButtonStyle = .primary
            skipButtonStyle = .ghost
            countColor = UIColor(resource: .mountain)

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
