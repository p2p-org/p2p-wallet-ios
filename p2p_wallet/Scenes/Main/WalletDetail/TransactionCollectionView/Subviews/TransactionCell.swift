//
//  TransactionCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/11/2020.
//

import Foundation
import BECollectionView

class TransactionCell: BaseCollectionViewCell, LoadableView {
    // MARK: - Properties
    var loadingViews: [UIView] {[
        imageView,
        transactionTypeLabel,
        amountInFiatLabel,
        descriptionLabel,
        amountInTokenLabel,
        swapTransactionImageView
    ]}
    
    // MARK: - Subviews
    private lazy var stackView = UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill)
    private lazy var imageView = TransactionImageView(size: 45, backgroundColor: .f6f6f8, cornerRadius: 12)
    private lazy var transactionTypeLabel = UILabel(textSize: 17, weight: .semibold)
    private lazy var amountInFiatLabel = UILabel(textSize: 15, weight: .semibold, textAlignment: .right)
    private lazy var descriptionLabel = UILabel(textSize: 15, weight: .medium, textColor: .textSecondary)
    private lazy var amountInTokenLabel = UILabel(textSize: 15, weight: .medium, textColor: .textSecondary, textAlignment: .right)
    private lazy var swapTransactionImageView = SwapTransactionImageView(height: 18)
    
    override func commonInit() {
        super.commonInit()
        contentView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(all: 20))
        
        stackView.addArrangedSubviews([
            imageView,
            UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UIStackView(axis: .horizontal, spacing: 8, alignment: .fill, distribution: .fill, arrangedSubviews: [
                    transactionTypeLabel, amountInFiatLabel
                ]),
                UIStackView(axis: .horizontal, spacing: 8, alignment: .fill, distribution: .fill, arrangedSubviews: [
                    descriptionLabel, swapTransactionImageView, amountInTokenLabel
                ])
            ])
        ])
        
        let separator = UIView.separator(height: 1, color: .separator)
        contentView.addSubview(separator)
        separator.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.init(all: 20).modifying(dBottom: -20), excludingEdge: .top)
        
        swapTransactionImageView.isHidden = true
    }
}

extension TransactionCell: BECollectionViewCell {
    func setUp(with item: AnyHashable?) {
        guard let transaction = item as? SolanaSDK.AnyTransaction else {return}
        // clear
        descriptionLabel.text = nil
        
        // type
        transactionTypeLabel.text = transaction.label
        
        // description texts
        switch transaction.value {
        case let transaction as SolanaSDK.CreateAccountTransaction:
            if let newToken = transaction.newToken {
                descriptionLabel.text = L10n.created(newToken.symbol)
            }
        case let transaction as SolanaSDK.CloseAccountTransaction:
            if let closedToken = transaction.closedToken {
                descriptionLabel.text = L10n.closed(closedToken.symbol)
            }
        case let transaction as SolanaSDK.TransferTransaction:
            switch transaction.transferType {
            case .send:
                transactionTypeLabel.text = L10n.transfer
                if let destination = transaction.destination?.pubkey
                {
                    descriptionLabel.text = L10n.to(destination.prefix(4) + "..." + destination.suffix(4))
                }
            case .receive:
                if let source = transaction.source?.pubkey
                {
                    descriptionLabel.text = L10n.fromToken(source.prefix(4) + "..." + source.suffix(4))
                }
            default:
                break
            }
            
        case let transaction as SolanaSDK.SwapTransaction:
            if let source = transaction.source,
                  let destination = transaction.destination
            {
                descriptionLabel.text = L10n.to(source.symbol, destination.symbol)
            }
            
        default:
            descriptionLabel.text = nil
        }
        
        // set up icon
        imageView.setUp(transaction: transaction)
        
        // amount in fiat
        amountInFiatLabel.text = nil
        amountInFiatLabel.textColor = .textBlack
        if let amountInFiat = transaction.amountInFiat
        {
            var amountText = "\(Defaults.fiat.symbol)\(abs(amountInFiat).toString(maximumFractionDigits: 4, showMinus: false))"
            var textColor = UIColor.textBlack
            if transaction.amount < 0 {
                amountText = "- " + amountText
            } else {
                amountText = "+ " + amountText
                textColor = .attentionGreen
            }
            amountInFiatLabel.text = amountText
            amountInFiatLabel.textColor = textColor
        }
        
        // amount
        amountInTokenLabel.text = "\(transaction.amount.toString(maximumFractionDigits: 9, showPlus: true)) \(transaction.symbol)"
    }
}
