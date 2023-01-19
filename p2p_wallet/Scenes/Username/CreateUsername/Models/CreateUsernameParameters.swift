import UIKit
import KeyAppUI

struct CreateUsernameParameters {
    let backgroundColor: UIColor
    let buttonStyle: TextButton.Style

    init(
        backgroundColor: UIColor = Asset.Colors.lime.color,
        buttonStyle: TextButton.Style = .primary
    ) {
        self.backgroundColor = backgroundColor
        self.buttonStyle = buttonStyle
    }
}
