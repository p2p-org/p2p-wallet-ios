//
//  MainFooterView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation

extension MainVC {
    class FooterView: SectionFooterView {
        lazy var addCoinButton = DashedButton(title: "+ \(L10n.addWallet)")
        
        override func commonInit() {
            super.commonInit()
            stackView.addArrangedSubview(addCoinButton.padding(UIEdgeInsets(x: 0, y: 16)))
        }
    }
}

