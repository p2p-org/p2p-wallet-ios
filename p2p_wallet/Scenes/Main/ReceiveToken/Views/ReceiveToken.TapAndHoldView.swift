//
//  ReceiveToken.TapAndHoldView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 21.01.2022.
//

import UIKit

extension ReceiveToken {
    final class TapAndHoldView: UIStackView {
        var closeHandler: (() -> Void)?

        init() {
            super.init(frame: .zero)

            spacing = 12

            addArrangedSubviews {
                UIImageView(width: 24, height: 24, image: .emptyAlert)
                UILabel(text: L10n.tapAndHoldToCopy, textSize: 15)
                UIImageView(width: 24, height: 24, image: .closeBanner)
                    .onTap(self, action: #selector(closeButtonDidTouch))
            }
        }

        @available(*, unavailable)
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc
        func closeButtonDidTouch() {
            closeHandler?()
        }
    }
}
