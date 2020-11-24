//
//  PriceCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/2/20.
//

import Foundation

class MainWalletCell: BaseCollectionViewCell, WalletCellType {
    lazy var stackView = UIStackView(axis: .horizontal, spacing: 16.adaptiveWidth, alignment: .top, distribution: .fill)
    lazy var coinLogoImageView = UIImageView(width: 32, height: 32, cornerRadius: 32 / 2)
    lazy var coinNameLabel = UILabel(text: "Coin name", textSize: 15, weight: .semibold)
    lazy var equityValueLabel = UILabel(text: "44,33 USD", textSize: 13)
    lazy var tokenCountLabel = UILabel(text: "0,00344 Tkns", textSize: 13, textColor: .secondary)
    lazy var graphView = UIImageView(width: 49, height: 15, image: .graphDemo)
    lazy var coinPriceLabel = UILabel(text: "12 800,99 US$", textSize: 13)
    lazy var coinChangeLabel = UILabel(text: "0.35% 24 hrs", textSize: 13, textColor: .secondary)
    
    var loadingViews: [UIView] {[coinLogoImageView, coinNameLabel, equityValueLabel, tokenCountLabel, graphView, coinPriceLabel, coinChangeLabel]}
    
    override func commonInit() {
        super.commonInit()
        contentView.backgroundColor = .textWhite
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        
        contentView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16.adaptiveWidth, left: 16.adaptiveWidth, bottom: 16.adaptiveWidth, right: 16.adaptiveWidth))
        
        let vStackView = UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill, arrangedSubviews: [
            row(arrangedSubviews: [coinNameLabel, graphView]),
            row(arrangedSubviews: [equityValueLabel, coinPriceLabel]),
            row(arrangedSubviews: [tokenCountLabel, coinChangeLabel])
        ])
        
        stackView.addArrangedSubviews([
            coinLogoImageView,
            vStackView
        ])
    }
    
    func setUp(with item: Wallet) {
        coinLogoImageView.setImage(urlString: item.icon)
        coinNameLabel.text = item.name
        tokenCountLabel.text = "\(item.amount.toString(maximumFractionDigits: 9)) \(item.symbol)"
        
        if let price = item.price {
            equityValueLabel.isHidden = false
            coinPriceLabel.isHidden = false
            coinChangeLabel.isHidden = false
            equityValueLabel.text = "\((PricesManager.bonfida.solPrice?.value * item.amount).toString(maximumFractionDigits: 9)) US$"
            coinPriceLabel.text = "\(price.value.toString()) US$"
            coinChangeLabel.text = "\((price.change24h?.percentage * 100).toString(maximumFractionDigits: 2, showPlus: true))% 24 hrs"
        } else {
            equityValueLabel.isHidden = true
            coinPriceLabel.isHidden = true
            coinChangeLabel.isHidden = true
        }
    }
    
    private func row(arrangedSubviews: [UIView]) -> UIStackView {
        let stackView = UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing)
        stackView.addArrangedSubviews(arrangedSubviews)
        return stackView
    }
}
