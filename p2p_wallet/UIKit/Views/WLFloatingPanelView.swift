//
//  WLRoundedCornerShadowView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation
import UIKit
import BEPureLayout

class WLFloatingPanelView: BERoundedCornerShadowView {
    // MARK: - Initializer
    init(contentInset: UIEdgeInsets = .zero) {
        super.init(cornerRadius: 0, contentInset: contentInset)
    }
    
    override func commonInit() {
        super.commonInit()
        stackView.axis = .vertical
        stackView.alignment = .fill
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        border(width: 1, color: .f2f2f7.onDarkMode(.white.withAlphaComponent(0.1)))
    }
}
