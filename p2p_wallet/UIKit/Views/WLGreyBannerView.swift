//
//  WLGreyBannerView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/11/2021.
//

import Foundation
import UIKit

class WLGreyBannerView: BEView {
    var contentInset: UIEdgeInsets {
        didSet {
            stackView.constraintToSuperviewWithAttribute(.top)?.constant = contentInset.top
            stackView.constraintToSuperviewWithAttribute(.left)?.constant = contentInset.left
            stackView.constraintToSuperviewWithAttribute(.bottom)?.constant = contentInset.bottom
            stackView.constraintToSuperviewWithAttribute(.right)?.constant = contentInset.right
        }
    }
    
    let stackView = UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill)
    
    init(contentInset: UIEdgeInsets = .init(all: 18)) {
        self.contentInset = contentInset
        super.init(frame: .zero)
    }
    
    override func commonInit() {
        super.commonInit()
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: contentInset)
        layer.cornerRadius = 12
        layer.masksToBounds = true
        backgroundColor = .a3a5ba.withAlphaComponent(0.05)
    }
}
