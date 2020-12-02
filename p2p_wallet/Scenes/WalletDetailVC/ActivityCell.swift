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
        typeLabel.text = item.type?.localizedString
        amountLabel.text = item.amount.toString(maximumFractionDigits: 4, showPlus: true) + " US$"
        if let timestamp = item.timestamp {
            dateLabel.text = dateFormatter.string(from: timestamp)
        } else {
            dateLabel.text = nil
        }
        
        tokensLabel.text = item.tokens.toString(maximumFractionDigits: 9, showPlus: true) + " " + item.symbol
    }
    
    var dateFormatter: DateFormatter {
        // Create Date Formatter
        let dateFormatter = DateFormatter()

        // Set Date Format
        dateFormatter.dateFormat = "dd MMM YYYY"
        return dateFormatter
    }
}
