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
            amountInTokenLabel
        ])
    }
}

class SwapTransactionSummaryView: TransactionSummaryView {
    lazy var sourceIconImageView = CoinLogoImageView(size: 44)
    lazy var destinationIconImageView = CoinLogoImageView(size: 44)
    
    lazy var sourceAmountLabel = createAmountLabel()
    lazy var destinationAmountLabel = createAmountLabel()
    
    lazy var sourceSymbolLabel = createSymbolLabel()
    lazy var destinationSymbolLabel = createSymbolLabel()
    
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
                swapIconImageView
            ]),
            destinationIconImageView,
            UIView.spacer
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
    
    private func createAmountLabel() -> UILabel {
        UILabel(textSize: 21, weight: .semibold, textAlignment: .center)
    }
    
    private func createSymbolLabel() -> UILabel {
        UILabel(textSize: 17, weight: .semibold, textColor: .textSecondary, textAlignment: .center)
    }
}
