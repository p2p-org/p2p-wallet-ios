//
//  BalancesOverviewView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/12/2020.
//

import Foundation
import Charts
import BECollectionView

class BalancesOverviewView: BERoundedCornerShadowView, LoadableView {
    lazy var equityValueLabel = UILabel(text: " ", textSize: 21, weight: .bold)
    lazy var changeLabel = UILabel(text: " ", textSize: 13, textColor: .textSecondary)
    lazy var chartView: PieChartView = {
        let chartView = PieChartView(width: 75, height: 75, cornerRadius: 75 / 2)
        chartView.usePercentValuesEnabled = true
        chartView.drawSlicesUnderHoleEnabled = false
        chartView.holeColor = .clear
        chartView.holeRadiusPercent = 0.58
        chartView.chartDescription?.enabled = false
        chartView.legend.enabled = false
        return chartView
    }()
    
    var loadingViews: [UIView] {[equityValueLabel, changeLabel, chartView]}
    
    init() {
        super.init(shadowColor: UIColor.black.withAlphaComponent(0.05), radius: 24, offset: CGSize(width: 0, height: 8), opacity: 1, cornerRadius: 12, contentInset: .init(x: 16, y: 14))
    }
    
    override func commonInit() {
        super.commonInit()
        layer.cornerRadius = 12
        layer.masksToBounds = true
        backgroundColor = .grayMain
        
        stackView.addArrangedSubviews([
            {
                let labelStackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill)
                labelStackView.addArrangedSubviews([
                    UILabel(text: L10n.totalBalance),
                    BEStackViewSpacing(12),
                    equityValueLabel,
                    BEStackViewSpacing(5),
                    changeLabel
                ])
                return labelStackView
            }(),
            chartView
        ])
    }
    
    func setUp(state: BEFetcherState, data: [Wallet]) {
        switch state {
        case .initializing:
            equityValueLabel.text = " "
            changeLabel.text = " "
            showLoading()
        case .loading:
            equityValueLabel.text = L10n.loading + "..."
            changeLabel.text = L10n.loading + "..."
            showLoading()
        case .loaded:
            let equityValue = data.reduce(0) { $0 + $1.amountInCurrentFiat }
            equityValueLabel.text = "\(Defaults.fiat.symbol) \(equityValue.toString(maximumFractionDigits: 9))"
            changeLabel.text = L10n.allTokens // FIXME: - temporarily, remove later
            setUpChartView(wallets: data)
            hideLoading()
        case .error:
            equityValueLabel.text = L10n.error.uppercaseFirst
            changeLabel.text = L10n.error.uppercaseFirst
            hideLoading()
        }
    }
    
    func setUpChartView(wallets: [Wallet]) {
        // filter
        let wallets = wallets
            .filter { $0.amountInCurrentFiat > 0}
        
        // get entries
        let entries = wallets
            .map { $0.amountInCurrentFiat}
            .map {PieChartDataEntry(value: $0)}
        
        let set = PieChartDataSet(entries: entries)
        set.sliceSpace = 2
        set.drawValuesEnabled = false
        set.selectionShift = 0
        
        set.colors = wallets.map {$0.token.indicatorColor}
        
        let data = PieChartData(dataSet: set)
        data.setValueTextColor(.clear)
        
        chartView.data = data
        chartView.highlightValues(nil)
    }
}
