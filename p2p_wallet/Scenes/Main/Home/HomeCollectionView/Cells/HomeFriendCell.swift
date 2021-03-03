//
//  HomeFriendCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/03/2021.
//

import Foundation

class HomeFriendCell: ListCollectionCell<String> {
    override func commonInit() {
        super.commonInit()
        contentView.col([
            UIImageView(width: 56, height: 56, backgroundColor: .gray, cornerRadius: 28),
            UILabel(text: "friend", textSize: 12, textAlignment: .center)
        ]).with(spacing: 8, alignment: .center)
    }
}
