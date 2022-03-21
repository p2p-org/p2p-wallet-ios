//
//  EmptyView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation

class EmptyView: MessageView {
    override func commonInit() {
        super.commonInit()
        let imageView = UIImageView(width: 98, height: 98, image: .emptyPlaceholder)
        stackView.insertArrangedSubview(imageView, at: 0)

        titleLabel.textColor = .textSecondary
        titleLabel.text = L10n.thereIsNothingInHere
        descriptionLabel.isHidden = true
    }
}
