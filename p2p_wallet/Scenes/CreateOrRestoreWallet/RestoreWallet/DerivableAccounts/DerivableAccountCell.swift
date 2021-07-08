//
//  DerivableAccountCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/05/2021.
//

import Foundation
import BECollectionView

class DerivableAccountCell: BaseCollectionViewCell, BECollectionViewCell {
    override var padding: UIEdgeInsets {.init(x: 20, y: 15)}
    
    lazy var logoImageView = CoinLogoImageView(size: 45)
    lazy var symbolLabel = UILabel(text: "SOL", textSize: 17, weight: .medium)
    lazy var addressLabel = UILabel(text: "7YVp...4XwL", textSize: 13, weight: .medium, textColor: .textSecondary)
    lazy var balanceInFiatLabel = UILabel(textSize: 17, weight: .medium)
    lazy var balanceLabel = UILabel(textSize: 13, weight: .medium, textColor: .textSecondary)
    
    override func commonInit() {
        super.commonInit()
        stackView.axis = .horizontal
        stackView.alignment = .center
        
        stackView.addArrangedSubviews {
            logoImageView
            
            UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill) {
                UIStackView(axis: .horizontal, spacing: 5, alignment: .center, distribution: .fill) {
                    symbolLabel
                    balanceInFiatLabel
                }
                
                UIStackView(axis: .horizontal, spacing: 5, alignment: .center, distribution: .fill) {
                    addressLabel
                    balanceLabel
                }
            }
        }
    }
    
    func setUp(with item: AnyHashable?) {
        guard let account = item as? DerivableAccount else {return}
        
        contentView.alpha = account.isBlured == true ? 0.5: 1
        
        let token = SolanaSDK.Token(
            _tags: [],
            chainId: 101,
            address: "So11111111111111111111111111111111111111112",
            symbol: "SOL",
            name: "Solana",
            decimals: 9,
            logoURI: nil,
            extensions: nil
        )
        logoImageView.setUp(token: token)
        addressLabel.text = account.info.publicKey.short()
        
        balanceInFiatLabel.text = (account.amount * account.price)
            .toString(maximumFractionDigits: 4, groupingSeparator: " ")
            + Defaults.fiat.symbol
        balanceLabel.text = account.amount?.toString(maximumFractionDigits: 9) + " " + "SOL"
    }
}
