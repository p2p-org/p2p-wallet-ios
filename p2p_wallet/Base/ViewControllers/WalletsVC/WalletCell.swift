//
//  WalletCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/11/2020.
//

import Foundation

class WalletCell: ListCollectionCell<Wallet>, LoadableView {
    lazy var stackView = UIStackView(axis: .horizontal, spacing: 16.adaptiveWidth, alignment: .top, distribution: .fill)
    lazy var coinLogoImageView = CoinLogoImageView(width: 45, height: 45, cornerRadius: 12)
    lazy var coinNameLabel = UILabel(text: "Coin name", textSize: 15, weight: .semibold, numberOfLines: 0)
    lazy var coinPriceLabel = UILabel(text: "12 800,99 US$", textSize: 13)
    lazy var tokenCountLabel = UILabel(text: "0,00344 Tkns", textSize: 13, textColor: .textSecondary)
    lazy var equityValueLabel = UILabel(text: "44,33 USD", textSize: 13)
    
    lazy var coinChangeLabel = UILabel(text: "0.35% 24 hrs", textSize: 13, textColor: .textSecondary)
    var loadingViews: [UIView] {[coinLogoImageView, coinNameLabel, tokenCountLabel, coinPriceLabel, equityValueLabel, coinChangeLabel]}
    
    override func commonInit() {
        super.commonInit()
        contentView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        
        // Override this method to arrange stackview
    }
    
    override func setUp(with item: Wallet) {
        super.setUp(with: item)
        coinLogoImageView.setUp(wallet: item)
        coinNameLabel.text = item.name /*+ (item.isProcessing == true ? " (\(L10n.creating))" : "")*/
        tokenCountLabel.text = "\(item.amount.toString(maximumFractionDigits: 9)) \(item.symbol)"
        
        if let price = item.price {
            equityValueLabel.isHidden = false
            coinPriceLabel.isHidden = false
            coinChangeLabel.isHidden = false
            
            equityValueLabel.text = "\(item.amountInUSD.toString(maximumFractionDigits: 4)) $"
            coinPriceLabel.text = "\(price.value.toString()) $"
            coinChangeLabel.text = "\((price.change24h?.percentage * 100).toString(maximumFractionDigits: 2, showPlus: true))% 24 hrs"
        } else {
            equityValueLabel.isHidden = true
            coinPriceLabel.isHidden = true
            coinChangeLabel.isHidden = true
        }
    }
}
