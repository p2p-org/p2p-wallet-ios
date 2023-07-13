import UIKit
import KeyAppUI

struct CreateUsernameParameters {
    let backgroundColor: ColorResource
    let buttonStyle: TextButton.Style

    init(
        backgroundColor: ColorResource = .lime,
        buttonStyle: TextButton.Style = .primary
    ) {
        self.backgroundColor = backgroundColor
        self.buttonStyle = buttonStyle
    }
}
