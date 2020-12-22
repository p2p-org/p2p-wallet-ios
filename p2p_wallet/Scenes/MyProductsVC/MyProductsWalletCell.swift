//
//  MyProductsWalletCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/12/2020.
//

import Foundation

class MyProductsWalletCell: MainWalletCell {
    override func commonInit() {
        super.commonInit()
        coinNameLabel.textColor = .textBlack
        coinPriceLabel.textColor = .textBlack
        addressLabel.textColor = .secondary
        tokenCountLabel.textColor = .secondary
    }
}
