//
//  DefiCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/3/20.
//

import Foundation

class DefiCell: BaseCollectionViewCell, CollectionCell {
    lazy var stackView = UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill)
    
    lazy var imageView = UIImageView(width: 32, height: 32, backgroundColor: .gray, cornerRadius: 16)
    lazy var titleLabel = UILabel(text: "Token exchange", textSize: 15, weight: .semibold, numberOfLines: 0)
    
    override func commonInit() {
        super.commonInit()
        backgroundColor = .textWhite
        contentView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        
        stackView.addArrangedSubviews([imageView, titleLabel])
    }
    
    func setUp(with item: String) {
        
    }
}
