//
//  WalletActionButton.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 19.01.2022.
//

import BEPureLayout
import UIKit
import KeyAppUI

final class WalletActionButton: BEView {
    init(actionType: WalletActionType, onTapHandler: @escaping () -> Void) {
        super.init(frame: .zero)

        let content = createContent(image: actionType.newIcon, title: actionType.text)
        addSubview(content)
        content.autoAlignAxis(toSuperviewAxis: .horizontal)
        content.autoAlignAxis(toSuperviewAxis: .vertical)
        heightAnchor.constraint(equalToConstant: 68).isActive = true
        widthAnchor.constraint(equalToConstant: 52).isActive = true

        onTap(onTapHandler)
    }

    private func createContent(image: UIImage, title: String) -> UIView {
        let stackView = UIStackView(axis: .vertical, spacing: 4, alignment: .center, distribution: .fill) {
            UIImageView(width: 52, height: 52, image: image)
            UILabel(text: title, textSize: 13, weight: .medium, textColor: Asset.Colors.night.color)
                .setup {
                    $0.font = .font(of: .label2, weight: .semibold)
                }
        }

        return stackView
    }
}
