//
//  MainFooterView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation
import Action

extension MainVC {
    class FirstSectionHeaderView: SectionHeaderView, LoadableView {
        lazy var equityValueLabel = UILabel(text: " ", textSize: 21, weight: .bold, textColor: .white)
        lazy var changeLabel = UILabel(text: " ", textSize: 13, textColor: .white)
        
        var loadingViews: [UIView] {[equityValueLabel, changeLabel]}
        
        override func commonInit() {
            super.commonInit()
            // remove all arranged subviews
            stackView.arrangedSubviews.forEach {$0.removeFromSuperview()}
            
            // add header
            stackView.addArrangedSubviews([
                UIView.row([
                    .col([
                        UILabel(text: L10n.totalBalance, textSize: 15, textColor: .white),
                        equityValueLabel,
                        changeLabel
                    ]),
                    UIImageView(width: 75, height: 75, image: .totalBalanceGraph)
                ])
                    .with(spacing: 16, alignment: .center, distribution: .fill)
                    .padding(.init(x: 16, y: 14), backgroundColor: .h2b2b2b, cornerRadius: 12)
                    .padding(.init(x: .defaultPadding, y: 0))
            ])
            
            stackView.constraintToSuperviewWithAttribute(.top)?.constant = 30
            stackView.constraintToSuperviewWithAttribute(.bottom)?.constant = -30
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
                    .text(" \(L10n.forTheLast24Hours)", size: 13, color: .white)
                hideLoading()
            case .error(let error):
                debugPrint(error)
                equityValueLabel.text = L10n.error.uppercaseFirst
                changeLabel.text = L10n.error.uppercaseFirst
                hideLoading()
            }
        }
    }
    
    class FirstSectionFooterView: SectionFooterView {
        var showProductsAction: CocoaAction?
        
        lazy var button: UIView = {
            let view = UIView(backgroundColor: UIColor.white.withAlphaComponent(0.1), cornerRadius: 12)
            view.row([
                UILabel(text: L10n.allMyBalances, textSize: 17, weight: .medium, textColor: .white),
                UIImageView(width: 8, height: 13, image: .nextArrow, tintColor: .secondary)
            ], padding: .init(x: 20, y: 16))
            return view
                .onTap(self, action: #selector(buttonDidTouch))
        }()
        
        override func commonInit() {
            super.commonInit()
            stackView.alignment = .fill
            stackView.addArrangedSubview(button.padding(.init(x: .defaultPadding, y: 30)))
        }
        
        @objc func buttonDidTouch() {
            showProductsAction?.execute()
        }
    }
}
