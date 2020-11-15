//
//  WCVFooterView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation

class WCVFooterView: SectionFooterView {
    lazy var addCoinButton = DashedButton(title: "+ \(L10n.addCoin)")
    
    override func commonInit() {
        addSubview(addCoinButton)
        addCoinButton.autoPinEdge(toSuperviewEdge: .top, withInset: 20)
        addCoinButton.autoPinEdge(toSuperviewEdge: .bottom, withInset: 20)
        addCoinButton.autoAlignAxis(toSuperviewAxis: .vertical)
    }
}
