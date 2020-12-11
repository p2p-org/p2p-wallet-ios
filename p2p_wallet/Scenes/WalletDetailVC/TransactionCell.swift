//
//  TransactionCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/11/2020.
//

import Foundation

class TransactionCell: BaseCollectionViewCell, CollectionCell {
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
                    .with(spacing: 5)
            ], padding: .init(all: 16))
            .with(distribution: .fill)
    }
    
    func setUp(with item: Transaction) {
        typeLabel.text = item.type?.localizedString ?? L10n.loading + "..."
        
        var amount = item.amountInUSD
        if item.type == .createAccount {
            amount = item.amount * PricesManager.shared.solPrice?.value
        }
        amountLabel.text = amount.toString(maximumFractionDigits: 4, showPlus: true) + " US$"
        
        if let timestamp = item.timestamp {
            dateLabel.text = dateFormatter.string(from: timestamp)
        } else {
            dateLabel.text = nil
        }
        
        var symbol = item.symbol
        if item.type == .createAccount {
            symbol = "SOL"
        }
        if let tokens = item.amount {
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
