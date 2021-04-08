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
    private lazy var imageView = TransactionImageView(width: 45, height: 45, backgroundColor: .f6f6f8, cornerRadius: 12)
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
        
        swapTransactionImageView.isHidden = true
    }
}

extension TransactionCell: BECollectionViewCell {
    func setUp(with item: AnyHashable?) {
        guard let transaction = item as? SolanaSDK.AnyTransaction else {return}
        switch transaction.value {
        case let transaction as SolanaSDK.CreateAccountTransaction:
            transactionTypeLabel.text = L10n.createAccount
        case let transaction as SolanaSDK.CloseAccountTransaction:
            transactionTypeLabel.text = L10n.closeAccount
        case let transaction as SolanaSDK.TransferTransaction:
            // TODO: - Send, receive
            transactionTypeLabel.text = L10n.transfer
        case let transaction as SolanaSDK.SwapTransaction:
            transactionTypeLabel.text = L10n.swap
        default:
            transactionTypeLabel.text = L10n.transaction
        }
        imageView.setUp(transaction: transaction)
    }
}
