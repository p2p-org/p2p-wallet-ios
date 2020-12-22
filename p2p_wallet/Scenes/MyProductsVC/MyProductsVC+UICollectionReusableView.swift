//
//  MyProductsVC+UICollectionReusableView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/12/2020.
//

import Foundation
import Action

extension _MyProductsVC {
    class FirstSectionHeaderView: SectionHeaderView, LoadableView {
        lazy var equityValueLabel = UILabel(text: " ", textSize: 21, weight: .bold)
        lazy var changeLabel = UILabel(text: " ", textSize: 13)
        
        var loadingViews: [UIView] {[equityValueLabel, changeLabel]}
        
        override func commonInit() {
            super.commonInit()
            headerLabel.removeFromSuperview()
            
            let totalBalanceView = UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill, arrangedSubviews: [
                {
                    let labelStackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill)
                    labelStackView.addArrangedSubviews([
                        UILabel(text: L10n.totalBalance, textSize: 15),
                        equityValueLabel,
                        changeLabel
                    ], withCustomSpacings: [12, 5])
                    return labelStackView
                }(),
                UIImageView(width: 75, height: 75, image: .totalBalanceGraph)
            ])
                .padding(.init(x: 16, y: 14), backgroundColor: .white, cornerRadius: 12)
            
            totalBalanceView.widthAnchor.constraint(greaterThanOrEqualToConstant: 335)
                .isActive = true
            
            totalBalanceView.addShadow(ofColor: UIColor.black.withAlphaComponent(0.07), radius: 24, offset: CGSize(width: 0, height: 4), opacity: 1)
            
            stackView.addArrangedSubviews([
                totalBalanceView
                    .padding(.init(x: .defaultPadding, y: 0)),
                headerLabel
                    .padding(.init(x: .defaultPadding, y: 0))
            ], withCustomSpacings: [32])
            
            stackView.constraintToSuperviewWithAttribute(.bottom)?.constant = -32
        }
        
        func setUp(with state: FetcherState<[Wallet]>) {
            switch state {
            case .initializing:
                equityValueLabel.text = " "
                changeLabel.text = " "
                hideLoading()
            case .loading:
                equityValueLabel.text = L10n.loading + "..."
                changeLabel.text = L10n.loading + "..."
                showLoading()
            case .loaded(let wallets):
                let equityValue = wallets.reduce(0) { $0 + $1.amountInUSD }
                equityValueLabel.text = "$ \(equityValue.toString(maximumFractionDigits: 2))"
                let changeValue = PricesManager.shared.solPrice?.change24h?.percentage * 100
                var color = UIColor.attentionGreen
                if changeValue < 0 {
                    color = .red
                }
                changeLabel.attributedText = NSMutableAttributedString()
                    .text("\(changeValue.toString(maximumFractionDigits: 2, showPlus: true))%", size: 13, color: color)
                    .text(" \(L10n.forTheLast24Hours)", size: 13)
                hideLoading()
            case .error(let error):
                debugPrint(error)
                equityValueLabel.text = L10n.error.uppercaseFirst
                changeLabel.text = L10n.error.uppercaseFirst
                hideLoading()
            }
        }
    }
}
