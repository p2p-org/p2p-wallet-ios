//
//  WalletCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/11/2020.
//

import Foundation

class WalletCell: BaseCollectionViewCell, WalletCellType {
    lazy var stackView = UIStackView(axis: .horizontal, spacing: 16.adaptiveWidth, alignment: .top, distribution: .fill)
    lazy var coinLogoImageView = UIImageView(width: 32, height: 32, cornerRadius: 32 / 2)
    lazy var coinNameLabel = UILabel(text: "Coin name", textSize: 15, weight: .semibold, numberOfLines: 0)
    lazy var coinPriceLabel = UILabel(text: "12 800,99 US$", textSize: 13)
    lazy var tokenCountLabel = UILabel(text: "0,00344 Tkns", textSize: 13, textColor: .secondary)
    lazy var equityValueLabel = UILabel(text: "44,33 USD", textSize: 13)
    
    lazy var coinChangeLabel = UILabel(text: "0.35% 24 hrs", textSize: 13, textColor: .secondary)
    var loadingViews: [UIView] {[coinLogoImageView, coinNameLabel, tokenCountLabel, coinPriceLabel, equityValueLabel, coinChangeLabel]}
    
    override func commonInit() {
        super.commonInit()
        contentView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16.adaptiveWidth, left: 16.adaptiveWidth, bottom: 16.adaptiveWidth, right: 16.adaptiveWidth))
        
        // Override this method to arrange stackview
    }
    
    func setUp(with item: Wallet) {
        coinLogoImageView.setImage(urlString: item.icon)
        coinNameLabel.text = item.name /*+ (item.isProcessing == true ? " (\(L10n.creating))" : "")*/
        tokenCountLabel.text = "\(item.amount.toString(maximumFractionDigits: 9)) \(item.symbol)"
        
        if let price = item.price {
            equityValueLabel.isHidden = false
            coinPriceLabel.isHidden = false
            coinChangeLabel.isHidden = false
            
            equityValueLabel.text = "\((PricesManager.shared.solPrice?.value * item.amount).toString(maximumFractionDigits: 4)) US$"
            coinPriceLabel.text = "\(price.value.toString()) US$"
            coinChangeLabel.text = "\((price.change24h?.percentage * 100).toString(maximumFractionDigits: 2, showPlus: true))% 24 hrs"
        } else {
            equityValueLabel.isHidden = true
            coinPriceLabel.isHidden = true
            coinChangeLabel.isHidden = true
        }
    }
}
