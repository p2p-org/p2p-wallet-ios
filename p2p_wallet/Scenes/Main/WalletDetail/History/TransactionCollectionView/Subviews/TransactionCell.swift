//
//  TransactionCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/11/2020.
//

import BECollectionView
import Foundation

class TransactionCell: BaseCollectionViewCell {
    override var padding: UIEdgeInsets { .init(all: 20) }

    // MARK: - Subviews

    private lazy var imageView = TransactionImageView(size: 45, backgroundColor: .grayPanel, cornerRadius: 12)
    private lazy var transactionTypeLabel = UILabel(textSize: 17, weight: .semibold)
    private lazy var amountInFiatLabel = UILabel(textSize: 15, weight: .semibold, textAlignment: .right)
    private lazy var transactionStatusIndicator = UIImageView(width: 20, height: 20, image: .transactionIndicatorPending)
    private lazy var descriptionLabel = UILabel(textSize: 15, weight: .medium, textColor: .textSecondary)
    private lazy var amountInTokenLabel = UILabel(textSize: 15, weight: .medium, textColor: .textSecondary, textAlignment: .right)
    private lazy var swapTransactionImageView = SwapTransactionImageView(height: 18)

    override func commonInit() {
        super.commonInit()

        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.alignment = .center

        stackView.addArrangedSubviews {
            imageView
            UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UIStackView(axis: .horizontal, spacing: 8, alignment: .fill, distribution: .fill, arrangedSubviews: [
                    transactionTypeLabel, amountInFiatLabel, BEStackViewSpacing(5), transactionStatusIndicator,
                ]),
                UIStackView(axis: .horizontal, spacing: 8, alignment: .fill, distribution: .fill, arrangedSubviews: [
                    descriptionLabel, swapTransactionImageView, amountInTokenLabel,
                ]),
            ])
        }

        let separator = UIView.defaultSeparator()
        contentView.addSubview(separator)
        separator.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(all: 20).modifying(dBottom: -20), excludingEdge: .top)

        swapTransactionImageView.isHidden = true
    }
}

extension TransactionCell: BECollectionViewCell {
    func setUp(with item: AnyHashable?) {
        guard let transaction = item as? SolanaSDK.ParsedTransaction
        else { return }

        // clear
        descriptionLabel.text = nil

        // type
        transactionTypeLabel.text = transaction.label

        // description texts
        var isUndefinedTransaction = false
        switch transaction.value {
        case let transaction as SolanaSDK.CreateAccountTransaction:
            if let newWallet = transaction.newWallet {
                descriptionLabel.text = L10n.created(newWallet.token.symbol)
            }
        case let transaction as SolanaSDK.CloseAccountTransaction:
            if let closedWallet = transaction.closedWallet {
                descriptionLabel.text = L10n.closed(closedWallet.token.symbol)
            }
        case let transaction as SolanaSDK.TransferTransaction:
            switch transaction.transferType {
            case .send:
                if let destination = transaction.destination {
                    descriptionLabel.text = L10n.to(destination.pubkey?.truncatingMiddle() ?? "")
                }
            case .receive:
                if let source = transaction.source {
                    descriptionLabel.text = L10n.fromToken(source.pubkey?.truncatingMiddle() ?? "")
                }
            default:
                break
            }

        case let transaction as SolanaSDK.SwapTransaction:
            if let source = transaction.source,
               let destination = transaction.destination
            {
                descriptionLabel.text = L10n.to(source.token.symbol, destination.token.symbol)
            }

        default:
            if let signature = transaction.signature {
                descriptionLabel.text = signature.prefix(4) + "..." + signature.suffix(4)
            }
            isUndefinedTransaction = true
        }

        // set up icon
        imageView.setUp(transaction: transaction)

        // amount in fiat
        amountInFiatLabel.text = nil
        amountInFiatLabel.textColor = .textBlack
        if let amountInFiat = transaction.amountInFiat {
            var amountText = "\(Defaults.fiat.symbol)\(abs(amountInFiat).toString(showMinus: false, autoSetMaximumFractionDigits: true))"
            var textColor = UIColor.textBlack
            if transaction.amount < 0 {
                amountText = "- " + amountText
            } else if transaction.amount > 0 {
                amountText = "+ " + amountText
                textColor = .attentionGreen
            } else {
                amountText = ""
            }
            amountInFiatLabel.text = amountText
            amountInFiatLabel.textColor = textColor
        }

        // amount
        amountInTokenLabel.text = nil
        if !isUndefinedTransaction {
            if transaction.amount != 0 {
                amountInTokenLabel.text = "\(transaction.amount.toString(maximumFractionDigits: 9, showPlus: true)) \(transaction.symbol)"
            }
        } else if let blockhash = transaction.blockhash {
            amountInTokenLabel.text = "#" + blockhash.prefix(4) + "..." + blockhash.suffix(4)
        }

        // status
        transactionStatusIndicator.isHidden = true
        switch transaction.status {
        case .requesting, .processing:
            transactionStatusIndicator.isHidden = false
            transactionStatusIndicator.image = .transactionIndicatorPending
        case .error:
            transactionStatusIndicator.isHidden = false
            transactionStatusIndicator.image = .transactionIndicatorError
        default:
            break
        }
    }
}
