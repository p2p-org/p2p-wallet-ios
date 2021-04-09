//
//  TransactionInfoRootView+Subviews.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/04/2021.
//

import Foundation

extension TransactionInfoRootView {
    class TransactionInfoSection<TitleView: UIView, ContentView: UIView>: BEView {
        lazy var stackView = UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill, arrangedSubviews: [titleView, contentView])
        
        let titleView: TitleView
        let contentView: ContentView
        
        init(titleView: TitleView, contentView: ContentView) {
            self.titleView = titleView
            self.contentView = contentView
            super.init(frame: .zero)
            configureForAutoLayout()
        }
        
        override func commonInit() {
            super.commonInit()
            let separator = UIView.separator(height: 1, color: .separator)
            addSubview(separator)
            separator.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
            
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .init(all: .defaultPadding))
        }
    }
    
    // MARK: - Summary views
    class SummaryView: BEView {
        lazy var stackView = UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill)
        override func commonInit() {
            super.commonInit()
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .init(x: .defaultPadding, y: 0))
        }
    }
    
    class DefaultSummaryView: SummaryView {
        lazy var amountInFiatLabel = UILabel(textSize: 27, weight: .bold, textAlignment: .center)
        lazy var amountInTokenLabel = UILabel(weight: .medium, textAlignment: .center)
        
        override func commonInit() {
            super.commonInit()
            stackView.addArrangedSubviews([
                amountInFiatLabel,
                amountInTokenLabel
            ])
        }
    }
    
    class SwapSummaryView: SummaryView {
        lazy var sourceIconImageView = CoinLogoImageView(width: 44, height: 44)
        lazy var destinationIconImageView = CoinLogoImageView(width: 44, height: 44)
        
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
            
            let swapIconImageView = UIImageView(width: 24, height: 24, image: .transactionSwap, tintColor: .a3a5ba)
                .padding(.init(all: 6), backgroundColor: .f6f6f8, cornerRadius: 12)
            
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
    
    // MARK: - Status view
    class TransactionStatusView: BEView {
        lazy var indicatorView = UIView(width: 8, height: 8, backgroundColor: .greenConfirmed, cornerRadius: 2)
        lazy var label = UILabel(text: L10n.completed, textSize: 13, weight: .semibold, textColor: .a3a5ba)
        
        init() {
            super.init(frame: .zero)
            configureForAutoLayout()
        }
        
        override func commonInit() {
            super.commonInit()
            
            backgroundColor = UIColor.f6f6f8.withAlphaComponent(0.5)
            layer.cornerRadius = 6
            layer.masksToBounds = true
            
            let stackView = UIStackView(axis: .horizontal, spacing: 6, alignment: .center, distribution: .fill, arrangedSubviews: [
                indicatorView, label
            ])
            
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .init(all: 6))
        }
    }
}
