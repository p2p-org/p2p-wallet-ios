//
//  TapAndHoldView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/03/2022.
//

import Foundation

final class TapAndHoldView: UIStackView {
    var closeHandler: (() -> Void)?

    init() {
        super.init(frame: .zero)

        spacing = 12

        addArrangedSubviews {
            UIImageView(width: 24, height: 24, image: .emptyAlert)
            UILabel(text: L10n.tapAndHoldToCopy, textSize: 15)
            UIView.closeBannerButton()
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
