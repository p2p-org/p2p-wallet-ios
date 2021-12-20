//
//  WalletCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/11/2020.
//

import ListPlaceholder

class WalletCell: BaseCollectionViewCell {
    override var padding: UIEdgeInsets {.zero}
    
    lazy var coinLogoImageView = CoinLogoImageView(size: 45)
    lazy var coinSymbolLabel = UILabel(text: "<Coin name>", weight: .semibold, numberOfLines: 0)
    let coinCheckMark = UIImageView(
        width: 28,
        height: 28,
        image: UIImage.check.withRenderingMode(.alwaysTemplate),
        tintColor: .black
    )
    lazy var coinPriceLabel = UILabel(text: "<12>", textSize: 13)
    lazy var tokenCountLabel = UILabel(text: "<0,00344 Tkns>", textSize: 13, textColor: .textSecondary)
    lazy var equityValueLabel = UILabel(text: "<44,33>", textSize: 13)
    
    lazy var coinChangeLabel = UILabel(text: "<0.35% 24 hrs>", textSize: 13, textColor: .textSecondary)
    
    override func commonInit() {
        super.commonInit()
        stackView.axis = .horizontal
        stackView.spacing = 16.adaptiveWidth
        stackView.alignment = .top
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        coinLogoImageView.tokenIcon.cancelPreviousTask()
        coinLogoImageView.tokenIcon.image = nil
    }

    func setIsSelected(isSelected: Bool) {
        coinLogoImageView.alpha = isSelected ? 0.2 : 1
        coinCheckMark.isHidden = !isSelected
        contentView.backgroundColor = isSelected ? .h5887ff.withAlphaComponent(0.2) : .clear
    }
    
    func setUp(with item: Wallet) {
        coinLogoImageView.setUp(wallet: item)
        if item.name.isEmpty {
            coinSymbolLabel.text = item.mintAddress.prefix(4) + "..." + item.mintAddress.suffix(4)
        } else {
            coinSymbolLabel.text = item.name /*+ (item.isProcessing == true ? " (\(L10n.creating))" : "")*/
        }
        tokenCountLabel.text = "\(item.amount.toString(maximumFractionDigits: 9)) \(item.token.symbol)"
        
        if let price = item.price {
            equityValueLabel.isHidden = false
            coinPriceLabel.isHidden = false
            coinChangeLabel.isHidden = false
            
            equityValueLabel.text = "\(item.amountInCurrentFiat.toString(maximumFractionDigits: 2)) \(Defaults.fiat.symbol)"
            coinPriceLabel.text = "\(price.value.toString()) \(Defaults.fiat.symbol)"
            coinChangeLabel.text = "\((price.change24h?.percentage * 100).toString(maximumFractionDigits: 2, showPlus: true))% 24 hrs"
        } else {
            equityValueLabel.isHidden = true
            coinPriceLabel.isHidden = true
            coinChangeLabel.isHidden = true
        }
    }
}
