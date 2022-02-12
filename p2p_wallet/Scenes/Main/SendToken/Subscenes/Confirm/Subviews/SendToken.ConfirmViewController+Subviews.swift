//
//  SendToken.ConfirmViewController+Subviews.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/02/2022.
//

import Foundation

extension SendToken.ConfirmViewController {
    class AmountSummaryView: UIStackView {
        // MARK: - Subviews
        private lazy var coinImageView = CoinLogoImageView(size: 44, cornerRadius: 12)
        private lazy var equityValueLabel = UILabel(text: "<Amount: ~$150>")
        private lazy var amountLabel = UILabel(text: "<1 BTC>", textSize: 17, weight: .semibold)
        
        init() {
            super.init(frame: .zero)
            
            set(axis: .horizontal, spacing: 12, alignment: .center, distribution: .fill)
            addArrangedSubviews {
                coinImageView
                UIStackView(axis: .vertical, spacing: 4, alignment: .fill, distribution: .fill) {
                    equityValueLabel
                    amountLabel
                }
            }
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setUp(wallet: Wallet?, amount: Double) {
            coinImageView.setUp(wallet: wallet)
            
            let amount = amount
            let amountInFiat = amount * wallet?.priceInCurrentFiat.orZero
            
            equityValueLabel.attributedText = NSMutableAttributedString()
                .text(L10n.amount.uppercaseFirst + ": ", size: 13, color: .textSecondary)
                .text(Defaults.fiat.symbol + amountInFiat.toString(maximumFractionDigits: 2), size: 13, weight: .medium)
            
            amountLabel.text = amount.toString(maximumFractionDigits: 9)
        }
    }
    
    class RecipientView: UIStackView {
        // MARK: - Subviews
        private lazy var nameLabel = UILabel(text: "<Recipient: a.p2p.sol>")
        private lazy var addressLabel = UILabel(text: "<DkmTQHutnUn9xWmismkm2zSvLQfiEkPQCq6rAXZKJnBw>", textSize: 17, weight: .semibold, numberOfLines: 0)
        
        init() {
            super.init(frame: .zero)
            
            set(axis: .horizontal, spacing: 12, alignment: .center, distribution: .fill)
            addArrangedSubviews {
                UIStackView(axis: .vertical, spacing: 4, alignment: .fill, distribution: .fill) {
                    nameLabel
                    addressLabel
                }
            }
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setUp(recipient: SendToken.Recipient?) {
            nameLabel.isHidden = false
            if let recipientName = recipient?.name {
                nameLabel.attributedText = NSMutableAttributedString()
                    .text(L10n.recipient.uppercaseFirst + ": ", size: 13, color: .textSecondary)
                    .text(recipientName, size: 13, weight: .medium)
            } else {
                nameLabel.isHidden = true
            }
            addressLabel.text = recipient?.address ?? L10n.chooseTheRecipient
        }
    }
    
    class SectionView: UIStackView {
        // MARK: - Subviews
        lazy var leftLabel = UILabel(text: "<Receive>", textSize: 15, textColor: .textSecondary)
        lazy var rightLabel = UILabel(text: "<0.00227631 renBTC (~$150)>", textSize: 15, numberOfLines: 0, textAlignment: .right)
            .withContentHuggingPriority(.required, for: .vertical)
        
        init(title: String) {
            super.init(frame: .zero)
            
            set(axis: .horizontal, spacing: 0, alignment: .top, distribution: .equalSpacing)
            addArrangedSubviews {
                leftLabel
                rightLabel
            }
            leftLabel.text = title
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
