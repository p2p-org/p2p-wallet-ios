//
//  NewsCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/3/20.
//

import BECollectionView
import Foundation

class NewsCell: BaseCollectionViewCell {
    override var padding: UIEdgeInsets { .init(all: 16) }
    lazy var imageView = UIImageView(backgroundColor: .gray)
    lazy var titleLabel = UILabel(
        text: "How it works",
        textSize: 21,
        weight: .semibold,
        textColor: .textWhite,
        numberOfLines: 0
    )
    lazy var descriptionLabel = UILabel(
        text: "The most important info you should know before investing",
        textSize: 17,
        textColor: .textWhite,
        numberOfLines: 0
    )

    override func commonInit() {
        super.commonInit()
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true

        contentView.addSubview(imageView)
        imageView.autoPinEdgesToSuperviewEdges()

        stackView.spacing = 5
        stackView.constraintToSuperviewWithAttribute(.top)?.isActive = false
        bringSubviewToFront(stackView)
        stackView.addArrangedSubviews {
            titleLabel
            descriptionLabel
        }
    }

    override func showLoading() {
        super.showLoading()
        imageView.hideLoader()
        imageView.showLoader(customGradientColor: .defaultLoaderGradientColors)
    }

    override func hideLoading() {
        super.hideLoading()
        imageView.hideLoader()
    }
}

extension NewsCell: BECollectionViewCell {
    func setUp(with item: AnyHashable?) {
        guard let item = item as? News else { return }
        titleLabel.text = item.title
        descriptionLabel.text = item.subtitle
    }
}
