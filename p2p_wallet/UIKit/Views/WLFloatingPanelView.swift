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
        super.init(shadowColor: UIColor.black.withAlphaComponent(0.05), radius: 8, offset: CGSize(width: 0, height: 1), opacity: 1, cornerRadius: 8, contentInset: contentInset)
    }
    
    override func commonInit() {
        super.commonInit()
        layer.cornerRadius = 12
        layer.masksToBounds = true
        
        stackView.axis = .vertical
        stackView.alignment = .fill
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        border(width: 1, color: .f2f2f7.onDarkMode(.white.withAlphaComponent(0.1)))
    }
}
