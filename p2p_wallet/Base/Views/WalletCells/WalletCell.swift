//
//  WalletCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/11/2020.
//

import Foundation

class WalletCell: BaseCollectionViewCell, LoadableView {
    lazy var stackView = UIStackView(axis: .horizontal, spacing: 16.adaptiveWidth, alignment: .top, distribution: .fill)
    lazy var coinLogoImageView = CoinLogoImageView(size: 45)
    lazy var coinNameLabel = UILabel(text: "<Coin name>", weight: .semibold, numberOfLines: 0)
    lazy var coinPriceLabel = UILabel(text: "<12>", textSize: 13)
    lazy var tokenCountLabel = UILabel(text: "<0,00344 Tkns>", textSize: 13, textColor: .textSecondary)
    lazy var equityValueLabel = UILabel(text: "<44,33>", textSize: 13)
    
    lazy var coinChangeLabel = UILabel(text: "<0.35% 24 hrs>", textSize: 13, textColor: .textSecondary)
    var loadingViews: [UIView] {[coinLogoImageView, coinNameLabel, tokenCountLabel, coinPriceLabel, equityValueLabel, coinChangeLabel]}
    
    override func commonInit() {
        super.commonInit()
        contentView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        
        // Override this method to arrange stackview
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        coinLogoImageView.tokenIcon.kf.cancelDownloadTask() // first, cancel currenct download task
        coinLogoImageView.tokenIcon.kf.setImage(with: URL(string: "")) // second, prevent kingfisher from setting previous image
        coinLogoImageView.tokenIcon.image = nil
    }
    
    func setUp(with item: Wallet) {
        coinLogoImageView.setUp(wallet: item)
        if item.name.isEmpty {
            coinNameLabel.text = item.mintAddress.prefix(4) + "..." + item.mintAddress.suffix(4)
        } else {
            coinNameLabel.text = item.name /*+ (item.isProcessing == true ? " (\(L10n.creating))" : "")*/
        }
        tokenCountLabel.text = "\(item.amount.toString(maximumFractionDigits: 9)) \(item.token.symbol)"
        
        if let price = item.price {
            equityValueLabel.isHidden = false
            coinPriceLabel.isHidden = false
            coinChangeLabel.isHidden = false
            
            equityValueLabel.text = "\(item.amountInCurrentFiat.toString(maximumFractionDigits: 4)) \(Defaults.fiat.symbol)"
            coinPriceLabel.text = "\(price.value.toString()) \(Defaults.fiat.symbol)"
            coinChangeLabel.text = "\((price.change24h?.percentage * 100).toString(maximumFractionDigits: 2, showPlus: true))% 24 hrs"
        } else {
            equityValueLabel.isHidden = true
            coinPriceLabel.isHidden = true
            coinChangeLabel.isHidden = true
        }
    }
}
