//
//  TransactionSumaryView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 04/06/2021.
//

import Foundation

class TransactionSummaryView: BEView {
    lazy var stackView = UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill)
    override func commonInit() {
        super.commonInit()
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(x: .defaultPadding, y: 0))
    }
}

class DefaultTransactionSummaryView: TransactionSummaryView {
    lazy var amountInFiatLabel = UILabel(textSize: 27, weight: .bold, textAlignment: .center)
    lazy var amountInTokenLabel = UILabel(weight: .semibold, textColor: .textSecondary, textAlignment: .center)

    override func commonInit() {
        super.commonInit()
        stackView.addArrangedSubviews([
            amountInFiatLabel,
            amountInTokenLabel,
        ])
    }
}

class SwapTransactionSummaryView: TransactionSummaryView {
    private lazy var sourceIconImageView = CoinLogoImageView(size: 44)
    private lazy var destinationIconImageView = CoinLogoImageView(size: 44)

    private lazy var sourceAmountLabel = createAmountLabel()
    private lazy var destinationAmountLabel = createAmountLabel()

    private lazy var sourceSymbolLabel = createSymbolLabel()
    private lazy var destinationSymbolLabel = createSymbolLabel()

    override func commonInit() {
        super.commonInit()

        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.distribution = .equalSpacing
        stackView.spacing = 22

        let swapIconImageView = UIImageView(width: 24, height: 24, image: .transactionSwap, tintColor: .iconSecondary)
            .padding(.init(all: 6), backgroundColor: .grayPanel, cornerRadius: 12)

        stackView.addArrangedSubviews([
            UIView.spacer,
            sourceIconImageView,
            UIStackView(axis: .vertical, arrangedSubviews: [
                UIView.spacer,
                swapIconImageView,
            ]),
            destinationIconImageView,
            UIView.spacer,
        ])

        swapIconImageView.autoAlignAxis(.horizontal, toSameAxisOf: sourceIconImageView)

        stackView.constraintToSuperviewWithAttribute(.bottom)?.isActive = false

        addSubview(sourceAmountLabel)
        sourceAmountLabel.autoPinEdge(.top, to: .bottom, of: sourceIconImageView, withOffset: 20)
        sourceAmountLabel.autoAlignAxis(.vertical, toSameAxisOf: sourceIconImageView)

        addSubview(sourceSymbolLabel)
        sourceSymbolLabel.autoPinEdge(.top, to: .bottom, of: sourceAmountLabel, withOffset: 4)
        sourceSymbolLabel.autoAlignAxis(.vertical, toSameAxisOf: sourceIconImageView)

        addSubview(destinationAmountLabel)
        destinationAmountLabel.autoPinEdge(.top, to: .bottom, of: destinationIconImageView, withOffset: 20)
        destinationAmountLabel.autoAlignAxis(.vertical, toSameAxisOf: destinationIconImageView)

        addSubview(destinationSymbolLabel)
        destinationSymbolLabel.autoPinEdge(.top, to: .bottom, of: destinationAmountLabel, withOffset: 4)
        destinationSymbolLabel.autoAlignAxis(.vertical, toSameAxisOf: destinationIconImageView)

        // pin bottom
        sourceSymbolLabel.autoPinEdge(toSuperviewEdge: .bottom)
    }

    func setUp(
        from: SolanaSDK.Token?,
        to: SolanaSDK.Token?,
        inputAmount: SolanaSDK.Lamports?,
        estimatedAmount: SolanaSDK.Lamports?
    ) {
        sourceIconImageView.setUp(token: from)
        if let inputAmount = inputAmount {
            sourceAmountLabel.text = (-(inputAmount.convertToBalance(decimals: from?.decimals)))
                .toString(maximumFractionDigits: 9)
        } else {
            sourceAmountLabel.text = nil
        }

        sourceSymbolLabel.text = from?.symbol

        destinationIconImageView.setUp(token: to)
        if let estimatedAmount = estimatedAmount {
            destinationAmountLabel.text = estimatedAmount.convertToBalance(decimals: to?.decimals)
                .toString(maximumFractionDigits: 9, showPlus: true)
        } else {
            destinationAmountLabel.text = nil
        }

        destinationSymbolLabel.text = to?.symbol
    }

    private func createAmountLabel() -> UILabel {
        UILabel(textSize: 21, weight: .semibold, textAlignment: .center)
    }

    private func createSymbolLabel() -> UILabel {
        UILabel(textSize: 17, weight: .semibold, textColor: .textSecondary, textAlignment: .center)
    }
}
