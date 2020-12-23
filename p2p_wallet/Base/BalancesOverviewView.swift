//
//  BalancesOverviewView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/12/2020.
//

import Foundation

class BalancesOverviewView: BERoundedCornerShadowView, LoadableView {
    lazy var equityValueLabel = UILabel(text: " ", textSize: 21, weight: .bold)
    lazy var changeLabel = UILabel(text: " ", textSize: 13)
    
    var loadingViews: [UIView] {[equityValueLabel, changeLabel]}
    
    init() {
        super.init(shadowColor: UIColor.black.withAlphaComponent(0.07), radius: 24, offset: CGSize(width: 0, height: 4), opacity: 1, cornerRadius: 12, contentInset: .init(x: 16, y: 14))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func commonInit() {
        super.commonInit()
        layer.cornerRadius = 12
        layer.masksToBounds = true
        
        stackView.addArrangedSubviews([
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
