//
// Created by Giang Long Tran on 09.11.21.
//

import UIKit

extension UIButton {
    static func text(
        text: String,
        image: UIImage? = nil,
        fontSize: CGFloat = 15,
        weight: UIFont.Weight = .regular,
        tintColor: UIColor = .black,
        padding: UIEdgeInsets = UIEdgeInsets(all: 10),
        iconPadding: Double = 8
    ) -> UIButton {
        let button = UIButton()

        button.setInsets(forContentPadding: padding, imageTitlePadding: image == nil ? 0 : iconPadding)
        button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize, weight: weight)
        button.setTitleColor(tintColor, for: .normal)
        button.setTitle(text, for: .normal)
        button.setImage(image, for: .normal)

        return button
    }
}

extension UIButton {
    func setInsets(
        forContentPadding contentPadding: UIEdgeInsets,
        imageTitlePadding: CGFloat
    ) {
        contentEdgeInsets = UIEdgeInsets(
            top: contentPadding.top,
            left: contentPadding.left,
            bottom: contentPadding.bottom,
            right: contentPadding.right + imageTitlePadding
        )
        titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: imageTitlePadding,
            bottom: 0,
            right: -imageTitlePadding
        )
    }
}
