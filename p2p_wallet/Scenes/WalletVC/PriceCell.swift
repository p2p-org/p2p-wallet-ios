//
//  PriceCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/2/20.
//

import Foundation

class PriceCell: BaseCollectionViewCell, CollectionCell {
    lazy var stackView = UIStackView(axis: .horizontal, spacing: 16.adaptiveWidth, alignment: .top, distribution: .equalSpacing)
    lazy var coinLogoImageView = UIImageView(width: 32, height: 32, backgroundColor: .gray, cornerRadius: 32 / 2)
    lazy var coinNameLabel = UILabel(text: "Coin name", textSize: 15, weight: .semibold, numberOfLines: 0)
    lazy var equityValueLabel = UILabel(text: "44,33 USD", textSize: 13)
    lazy var tokenCountLabel = UILabel(text: "0,00344 Tkns", textSize: 13, textColor: UIColor.textBlack.withAlphaComponent(0.5), numberOfLines: 0)
    lazy var graphView = UIImageView(width: 49, height: 15, image: .graphDemo)
    lazy var coinPriceLabel = UILabel(text: "12 800,99 US$", textSize: 13)
    lazy var coinChangeLabel = UILabel(text: "0.35% 24 hrs", textSize: 13, textColor: UIColor.textBlack.withAlphaComponent(0.5), numberOfLines: 0)
    
    override func commonInit() {
        super.commonInit()
        contentView.backgroundColor = .textWhite
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        
        contentView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16.adaptiveWidth, left: 16.adaptiveWidth, bottom: 16.adaptiveWidth, right: 16.adaptiveWidth))
        
        let coinInfoView: UIStackView = {
            let stackView = UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill)
            stackView.addArrangedSubviews([
                coinNameLabel,
                equityValueLabel,
                tokenCountLabel
            ])
            stackView.setCustomSpacing(10, after: equityValueLabel)
            return stackView
        }()
        
        let priceInfoView: UIStackView = {
            let stackView = UIStackView(axis: .vertical, spacing: 8, alignment: .leading, distribution: .fill)
            stackView.addArrangedSubviews([
                graphView,
                coinPriceLabel,
                coinChangeLabel
            ])
            stackView.setCustomSpacing(10, after: coinPriceLabel)
            return stackView
        }()
        
        stackView.addArrangedSubview(coinLogoImageView)
        stackView.addArrangedSubview(coinInfoView)
        stackView.addArrangedSubview(priceInfoView)
    }
    
    func setUp(with item: String) {
        
    }
}
