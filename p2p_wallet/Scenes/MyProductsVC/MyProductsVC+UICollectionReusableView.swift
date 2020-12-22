//
//  MyProductsVC+UICollectionReusableView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/12/2020.
//

import Foundation
import Action

extension MyProductsVC {
    class FirstSectionHeaderView: SectionHeaderView, LoadableView {
        var addCoinAction: CocoaAction?
        
        lazy var equityValueLabel = UILabel(text: "12 000$", textSize: 21, weight: .bold)
        lazy var changeLabel = UILabel(text: "+3.5 \(L10n.forTheLast24Hours)", textSize: 13)
        
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
                UIView.row([
                    UILabel(text: L10n.allMyProducts, textSize: 21, weight: .semibold),
                    UIImageView(width: 24, height: 24, image: .walletAdd, tintColor: .h5887ff)
                        .padding(.init(all: 10), backgroundColor: .eff3ff, cornerRadius: 12)
                        .onTap(self, action: #selector(buttonAddCoinDidTouch))
                ])
                    .padding(.init(x: .defaultPadding, y: 0)),
                totalBalanceView
                    .padding(.init(x: .defaultPadding, y: 0)),
                headerLabel
                    .padding(.init(x: .defaultPadding, y: 0))
            ], withCustomSpacings: [20, 32])
            
            DispatchQueue.main.async {
                self.showLoading()
            }
        }
        
        func setUp(with state: FetcherState<[Wallet]>) {
            switch state {
            case .initializing:
                equityValueLabel.text = " "
                changeLabel.text = " "
                hideLoading()
            case .loading:
                equityValueLabel.text = "Loading..."
                changeLabel.text = "loading..."
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
        
        @objc func buttonAddCoinDidTouch() {
            addCoinAction?.execute()
        }
    }
}
