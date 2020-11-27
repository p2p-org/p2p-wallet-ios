//
//  ProcessingVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/11/2020.
//

import Foundation

class ProcessingVC: WLCenterSheet {
    override var padding: UIEdgeInsets {.init(all: 52)}
    override func setUp() {
        super.setUp()
        stackView.spacing = 48
        stackView.alignment = .center
        stackView.addArrangedSubviews([
            UIImageView(width: 143, height: 137, image: .walletIntro),
            UILabel(text: L10n.processing + "...", textSize: 17, weight: .semibold)
        ])
        
    }
}
