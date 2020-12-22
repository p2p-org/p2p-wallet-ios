//
//  FriendCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/12/2020.
//

import Foundation

class FriendCell: BaseCollectionViewCell {
    override func commonInit() {
        super.commonInit()
        contentView.col([
            UIImageView(width: 56, height: 56, backgroundColor: .gray, cornerRadius: 28),
            UILabel(text: "friend", textSize: 12, textAlignment: .center)
        ]).with(spacing: 8, alignment: .center)
    }
}
