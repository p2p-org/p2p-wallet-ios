//
//  SectionFooterView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation

class SectionFooterView: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
    }
}

class EmptySectionFooterView: SectionFooterView {
    override func commonInit() {
        autoSetDimension(.height, toSize: 0)
    }
}
