//
//  BalancesOverviewView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/12/2020.
//

import Foundation
import Charts
import BECollectionView
import UIKit

class BalancesOverviewView: BERoundedCornerShadowView {
    // MARK: - Subviews
    private lazy var equityValueLabel = UILabel(text: " ", textSize: 20, weight: .bold, textAlignment: .right)
    private lazy var changeLabel = UILabel(text: " ", textSize: 13)
    private lazy var chartView: PieChartView = {
        let chartView = PieChartView(width: 64, height: 64, cornerRadius: 64 / 2)
        chartView.usePercentValuesEnabled = true
        chartView.drawSlicesUnderHoleEnabled = false
        chartView.holeColor = .clear
        chartView.holeRadiusPercent = 0.58
        chartView.chartDescription?.enabled = false
        chartView.legend.enabled = false
        chartView.noDataText = L10n.noChartDataAvailable
        return chartView
    }()
    private lazy var sendButton = createButton(image: .buttonSend, title: L10n.send)
    private lazy var receiveButton = createButton(image: .buttonReceive, title: L10n.receive)
    private lazy var swapButton = createButton(image: .buttonSwap, title: L10n.swap)
    
    // MARK: - Initializer
    init() {
        super.init(shadowColor: UIColor.black.withAlphaComponent(0.05), radius: 8, offset: CGSize(width: 0, height: 1), opacity: 1, cornerRadius: 8)
        self.border(width: 1, color: .f2f2f7.onDarkMode(.white.withAlphaComponent(0.1)))
    }
    
    override func commonInit() {
        super.commonInit()
        layer.cornerRadius = 12
        layer.masksToBounds = true
        backgroundColor = .grayMain
        
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.addArrangedSubviews {
            UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .fill) {
                chartView
                UIStackView(axis: .vertical, spacing: 4, alignment: .fill, distribution: .fill) {
                    UILabel(text: L10n.combinedTokensValue, textSize: 13, textColor: .textSecondary, textAlignment: .right)
                    equityValueLabel
                }
            }
                .padding(.init(x: 24, y: 13))
            
            UIView.separator(height: 1, color: .separator)
            
            UIStackView(axis: .horizontal, spacing: 0, alignment: .fill, distribution: .fillEqually) {
                sendButton
                receiveButton
                swapButton
            }
        }
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
            equityValueLabel.text = "\(Defaults.fiat.symbol) \(equityValue.toString(maximumFractionDigits: 2))"
            changeLabel.text = L10n.allTokens
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
    
    func showLoading() {
        stackView.arrangedSubviews.forEach {$0.hideLoader()}
        stackView.arrangedSubviews.forEach {$0.showLoader()}
    }
    func hideLoading() {
        stackView.arrangedSubviews.forEach {$0.hideLoader()}
    }
}

private func createButton(image: UIImage, title: String) -> UIView {
    let view = UIView(forAutoLayout: ())
    
    let stackView = UIStackView(axis: .horizontal, spacing: 4, alignment: .center, distribution: .fill)
        {
            UIImageView(width: 24, height: 24, image: image, tintColor: .h5887ff)
            UILabel(text: title, textSize: 15, weight: .medium, textColor: .h5887ff)
        }
    
    view.addSubview(stackView)
    stackView.autoAlignAxis(toSuperviewAxis: .vertical)
    stackView.autoPinEdge(toSuperviewEdge: .top, withInset: 18)
    stackView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 18)
    return view
}
