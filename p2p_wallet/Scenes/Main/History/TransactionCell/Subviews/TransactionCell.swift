//
//  TransactionCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/11/2020.
//

import BECollectionView
import Foundation
import SolanaSwift
import TransactionParser
import UIKit
import KeyAppUI

class TransactionCell: BaseCollectionViewCell, BECollectionViewCell {
    override var padding: UIEdgeInsets { .init(x: 16, y: 8) }

    // MARK: - Subviews

    lazy var imageView = TransactionImageView(
        size: 48,
        backgroundColor: .grayPanel,
        cornerRadius: 16,
        miniIconsSize: 29
    )

    lazy var transactionTypeLabel = UILabel(textSize: 16)
    lazy var amountInFiatLabel = UILabel(textSize: 16, weight: .medium, textAlignment: .right)

    lazy var descriptionLabel = UILabel(textSize: 12, textColor: .textSecondary)
    private lazy var amountInTokenLabel = UILabel(textSize: 12, textColor: .textSecondary, textAlignment: .right)

    lazy var leftStackView = UIStackView(
        axis: .vertical,
        spacing: 6,
        alignment: .leading,
        arrangedSubviews: [transactionTypeLabel, descriptionLabel]
    )
    lazy var rightStackView = UIStackView(
        axis: .vertical,
        spacing: 6,
        alignment: .trailing,
        arrangedSubviews: [amountInFiatLabel, amountInTokenLabel]
    )

    override func commonInit() {
        super.commonInit()

        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .center
        imageView.layer.cornerRadius = 12

        stackView.addArrangedSubviews {
            imageView
            UIStackView(axis: .horizontal, spacing: 8, alignment: .center, arrangedSubviews: [
                leftStackView,
                rightStackView,
            ])
        }

        setupSkeleton()
    }

    private func setupSkeleton() {
        transactionTypeLabel.layer.cornerRadius = 12
        amountInFiatLabel.layer.cornerRadius = 12
        descriptionLabel.layer.cornerRadius = 12
        amountInTokenLabel.layer.cornerRadius = 12
        transactionTypeLabel.text = "               "
        amountInFiatLabel.text = "                           "
        descriptionLabel.text = "                        "
        amountInTokenLabel.text = "                    "

        NSLayoutConstraint.activate([
            transactionTypeLabel.heightAnchor.constraint(equalToConstant: 19),
            amountInFiatLabel.heightAnchor.constraint(equalToConstant: 16),
            descriptionLabel.heightAnchor.constraint(equalToConstant: 18),
            amountInTokenLabel.heightAnchor.constraint(equalToConstant: 18),
        ])
    }

    // MARK: - BECollectionViewCell

    func setUp(with item: AnyHashable?) {
        guard let item = item as? HistoryItem else { return }
        
        imageView.backgroundView.backgroundColor = .grayPanel
        
        transactionTypeLabel.textColor = .textBlack
        amountInFiatLabel.textColor = .textBlack
        
        switch item {
        case let .parsedTransaction(transaction):
            imageView.backgroundView.layer.cornerRadius = 16
            setUp(with: transaction)
        case let .sellTransaction(transaction):
            imageView.backgroundView.layer.cornerRadius = 24
            setUp(with: transaction)
        }
    }

    private func setUp(with transaction: ParsedTransaction) {
        // clear
        descriptionLabel.text = nil
        amountInTokenLabel.isHidden = false

        // type
        transactionTypeLabel.font = transactionTypeLabel.font.withWeight(.regular)
        transactionTypeLabel.text = transaction.label

        // description texts
        var isUndefinedTransaction = false
        switch transaction.info {
        case let transaction as CreateAccountInfo:
            if let newWallet = transaction.newWallet {
                descriptionLabel.text = L10n.created(newWallet.token.symbol)
            }
        case let transaction as CloseAccountInfo:
            if let closedWallet = transaction.closedWallet {
                descriptionLabel.text = L10n.closed(closedWallet.token.symbol)
            }
        case let transaction as TransferInfo:
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
        case let transaction as SwapInfo:
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
        switch transaction.info {
        case let transaction as SwapInfo:
            imageView.setUp(imageType: .fromOneToOne(
                from: transaction.source?.token,
                to: transaction.destination?.token
            ))
        default:
            imageView.setUp(imageType: .oneImage(image: transaction.icon))
        }

        // set up status icon
        var statusImage: UIImage?
        switch transaction.status {
        case .requesting, .processing:
            statusImage = .transactionIndicatorPending
        case .error:
            statusImage = .transactionIndicatorError
        default:
            break
        }
        imageView.setUp(statusImage: statusImage)

        // amount in fiat
        amountInFiatLabel.text = nil
        amountInFiatLabel.textColor = .textBlack
        if let amountInFiat = transaction.amountInFiat {
            var amountText =
                "\(Defaults.fiat.symbol)\(abs(amountInFiat).toString(maximumFractionDigits: 2, showMinus: false))"
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
                amountInTokenLabel
                    .text =
                    "\(transaction.amount.toString(maximumFractionDigits: 9, showPlus: true)) \(transaction.symbol)"
            }
        } else if let blockhash = transaction.blockhash {
            amountInTokenLabel.text = "#" + blockhash.prefix(4) + "..." + blockhash.suffix(4)
        }

        // modify swap value
        switch transaction.info {
        case _ as SwapInfo:
            amountInFiatLabel.text = amountInFiatLabel.text?.replacingOccurrences(of: "+", with: "")
            amountInFiatLabel.text = amountInFiatLabel.text?.replacingOccurrences(of: "-", with: "")
            amountInFiatLabel.textColor = .textBlack
        default:
            return
        }
    }

    private func setUp(with transaction: SellDataServiceTransaction) {
        // reset
        transactionTypeLabel.font = transactionTypeLabel.font.withWeight(.semibold)
        amountInTokenLabel.isHidden = true

        // get infos
        let statusImage: UIImage
        let title: String
        let subtitle: String

        switch transaction.status {
        case .waitingForDeposit:
            statusImage = .transactionIndicatorSellPending
            title = L10n
                .youNeedToSendSOL(transaction.baseCurrencyAmount
                    .toString(maximumFractionDigits: 9, groupingSeparator: ""))
            subtitle = L10n.to("..." + transaction.depositWallet.suffix(4))
        case .pending:
            statusImage = .transactionIndicatorSellPending
            title = L10n.processing
            subtitle = L10n.toYourBankAccount
        case .completed:
            statusImage = .transactionIndicatorSellPending
            title = L10n.fundsWereSent
            subtitle = L10n.toYourBankAccount
        case .failed:
            imageView.backgroundView.backgroundColor = UIColor(red: 1, green: 0.863, blue: 0.914, alpha: 1)
            statusImage = .transactionIndicatorSellExpired
            title = L10n.youVeNotSent
            subtitle = L10n.to("SOL", "Moonpay")
            
            transactionTypeLabel.textColor = Asset.Colors.rose.color
            amountInFiatLabel.textColor = Asset.Colors.rose.color
        }

        let amountInFiatText = "$" + transaction.quoteCurrencyAmount
            .toString(maximumFractionDigits: 2) // FIXME: - Currency???

        // set up
        imageView.setUp(imageType: .oneImage(image: statusImage))
        imageView.setUp(statusImage: nil)
        transactionTypeLabel.text = title
        descriptionLabel.text = subtitle
        amountInFiatLabel.text = amountInFiatText
    }
}

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let newDescriptor = fontDescriptor.addingAttributes([.traits: [
            UIFontDescriptor.TraitKey.weight: weight,
        ]])
        return UIFont(descriptor: newDescriptor, size: pointSize)
    }
}
