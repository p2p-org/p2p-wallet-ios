//
//  ActivityCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/11/2020.
//

import Foundation

class ActivityCell: BaseCollectionViewCell, CollectionCell {
    let iconImageView = UIImageView(width: 32, height: 32, backgroundColor: .gray, cornerRadius: 16)
    let typeLabel = UILabel(textSize: 15, weight: .bold)
    let amountLabel = UILabel(textSize: 13, weight: .medium)
    let dateLabel = UILabel(textSize: 13, textColor: .secondary)
    let tokensLabel = UILabel(textSize: 13, textColor: .secondary)
    
    var loadingViews: [UIView] {[iconImageView, typeLabel, amountLabel, dateLabel, tokensLabel]}
    
    override func commonInit() {
        super.commonInit()
        contentView.backgroundColor = .textWhite
        contentView
            .row([
                iconImageView,
                UIView.col([
                    .row([typeLabel, amountLabel]),
                    .row([dateLabel, tokensLabel])
                ])
                    .with(spacing: 5, alignment: .fill, distribution: .fill)
            ], padding: .init(all: 16))
            .with(distribution: .fill)
    }
    
    func setUp(with item: Activity) {
        typeLabel.text = item.type?.localizedString ?? L10n.loading + "..."
        
        if let amount = item.amount {
            amountLabel.text = amount.toString(maximumFractionDigits: 4, showPlus: true) + " US$"
        } else {
            amountLabel.text = nil
        }
        
        if let timestamp = item.timestamp {
            dateLabel.text = dateFormatter.string(from: timestamp)
        } else {
            dateLabel.text = nil
        }
        
        var symbol = item.symbol
        if item.type == .createAccount {
            symbol = "SOL"
        }
        if let tokens = item.tokens {
            tokensLabel.text = tokens.toString(maximumFractionDigits: 9, showPlus: true) + " " + symbol
        } else {
            tokensLabel.text = nil
        }
        
    }
    
    var dateFormatter: DateFormatter {
        // Create Date Formatter
        let dateFormatter = DateFormatter()

        // Set Date Format
        dateFormatter.dateFormat = "dd MMM YYYY"
        return dateFormatter
    }
}
