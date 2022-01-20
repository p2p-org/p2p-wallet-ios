//
//  WalletActionButton.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 19.01.2022.
//

import UIKit
import BEPureLayout

final class WalletActionButton: BEView {
    init(actionType: WalletActionType, onTapHandler: @escaping () -> Void) {
        super.init(frame: .zero)

        let content = createContent(image: actionType.icon, title: actionType.text)
        addSubview(content)
        content.autoAlignAxis(toSuperviewAxis: .horizontal)
        content.autoAlignAxis(toSuperviewAxis: .vertical)

        self.onTap(onTapHandler)
    }

    private func createContent(image: UIImage, title: String) -> UIView {
        let stackView = UIStackView(axis: .vertical, spacing: 6, alignment: .center, distribution: .fill)
            {
                UIImageView(width: 20, height: 20, image: image.withRenderingMode(.alwaysTemplate), tintColor: .white)
                UILabel(text: title, textSize: 13, weight: .medium, textColor: .white)
            }

        return stackView
    }
}
