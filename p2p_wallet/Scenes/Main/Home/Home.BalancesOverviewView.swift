//
//  Home.BalancesOverviewView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/11/2021.
//

import BECollectionView
import Charts
import Foundation

extension Home {
    class BalancesOverviewView: WLOverviewView {
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

        private lazy var buyButton = createButton(image: .buttonSend, title: L10n.buy)
            .onTap { [unowned self] in self.didTapBuy?() }
        private lazy var sendButton = createButton(image: .buttonSend, title: L10n.send)
            .onTap { [unowned self] in self.didTapSend?() }
        private lazy var receiveButton = createButton(image: .buttonReceive, title: L10n.receive)
            .onTap { [unowned self] in self.didTapReceive?() }
        private lazy var swapButton = createButton(image: .buttonSwap, title: L10n.swap)
            .onTap { [unowned self] in self.didTapSwap?() }

        public lazy var topStackConstraint = stackView.autoPinEdge(toSuperviewEdge: .top)

        // MARK: - Callbacks

        var didTapBuy: (() -> Void)?
        var didTapSend: (() -> Void)?
        var didTapReceive: (() -> Void)?
        var didTapSwap: (() -> Void)?

        override func commonInit() {
            super.commonInit()

            layer.cornerRadius = 8
        }

        override func createTopView() -> UIView {
            UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .fill) {
                chartView
                UIStackView(axis: .vertical, spacing: 4, alignment: .fill, distribution: .fill) {
                    UILabel(
                        text: L10n.combinedTokensValue,
                        textSize: 13,
                        textColor: .textSecondary,
                        textAlignment: .right
                    )
                    equityValueLabel
                }
            }
            .padding(.init(x: 24, y: 13))
        }

        override func createButtonsView() -> UIView {
            UIStackView(axis: .horizontal, spacing: 0, alignment: .fill, distribution: .fillEqually) {
//                buyButton
                sendButton
                receiveButton
                swapButton
            }
        }

        override func layoutStackView() {
            topStackConstraint.priority = .defaultHigh
            stackView.autoPinEdge(toSuperviewEdge: .top, withInset: .zero, relation: .lessThanOrEqual)
            stackView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
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
                .filter { $0.amountInCurrentFiat > 0 }

            // get entries
            let entries = wallets
                .map(\.amountInCurrentFiat)
                .map { PieChartDataEntry(value: $0) }

            let set = PieChartDataSet(entries: entries)
            set.sliceSpace = 2
            set.drawValuesEnabled = false
            set.selectionShift = 0

            set.colors = wallets.map(\.token.indicatorColor)

            let data = PieChartData(dataSet: set)
            data.setValueTextColor(.clear)

            chartView.data = data
            chartView.highlightValues(nil)
        }

        @objc
        private func buttonSendDidTouch() {
            didTapSend?()
        }

        @objc
        private func buttonReceiveDidTouch() {
            didTapReceive?()
        }

        @objc
        private func buttonSwapDidTouch() {
            didTapSwap?()
        }
    }
}
