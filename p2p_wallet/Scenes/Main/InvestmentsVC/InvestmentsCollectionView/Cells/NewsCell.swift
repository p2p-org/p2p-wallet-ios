//
//  NewsCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/3/20.
//

import Foundation
import BECollectionView

class NewsCell: BaseCollectionViewCell {
    lazy var imageView = UIImageView(backgroundColor: .gray)
    lazy var titleLabel = UILabel(text: "How it works", textSize: 21, weight: .semibold, textColor: .textWhite, numberOfLines: 0)
    lazy var descriptionLabel = UILabel(text: "The most important info you should know before investing", textSize: 17, textColor: .textWhite, numberOfLines: 0)
    
    lazy var textStackView = UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill) {
        titleLabel
        descriptionLabel
    }
    
    override func commonInit() {
        super.commonInit()
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        
        contentView.addSubview(imageView)
        imageView.autoPinEdgesToSuperviewEdges()
        
        contentView.addSubview(textStackView)
        textStackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(all: 16), excludingEdge: .top)
        
    }
    
    func showLoading() {
        textStackView.hideLoader()
        textStackView.showLoader()
        
        imageView.hideLoader()
        imageView.showLoader()
    }
    func hideLoading() {
        textStackView.hideLoader()
    }
}

extension NewsCell: BECollectionViewCell {
    func setUp(with item: AnyHashable?) {
        guard let item = item as? News else {return}
        titleLabel.text = item.title
        descriptionLabel.text = item.subtitle
    }
}
