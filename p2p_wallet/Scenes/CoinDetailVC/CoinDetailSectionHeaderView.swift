//
//  CoinDetailSectionHeaderView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation

class CoinDetailSectionHeaderView: SectionHeaderView {
    lazy var amountLabel = UILabel(text: "$120,00", textSize: 25, weight: .semibold, textColor: .textBlack, textAlignment: .center)
    lazy var changeLabel = UILabel(text: "+ 0,16 US$ (0,01%) 24 hrs", textSize: 15, textColor: .secondary, textAlignment: .center)
    override func commonInit() {
        super.commonInit()
        stackView.insertArrangedSubview(amountLabel, at: 0)
        stackView.insertArrangedSubview(changeLabel, at: 1)
        stackView.insertArrangedSubview(UIImageView(width: 374, height: 256, image: .graphDetailDemo), at: 2)
    }
}
