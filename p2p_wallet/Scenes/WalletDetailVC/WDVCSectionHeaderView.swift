//
//  WDVCSectionHeaderView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation
import Charts

class WDVCSectionHeaderView: SectionHeaderView {
    lazy var amountLabel = UILabel(text: "$120,00", textSize: 25, weight: .semibold, textColor: .textBlack, textAlignment: .center)
    lazy var changeLabel = UILabel(text: "+ 0,16 US$ (0,01%) 24 hrs", textSize: 15, textColor: .secondary, textAlignment: .center)
    lazy var lineChartView: ChartView = {
        let chartView = ChartView(height: 257)
        chartView.chartDescription?.enabled = false
        chartView.leftAxis.drawAxisLineEnabled = false
        chartView.leftAxis.drawLabelsEnabled = false
        chartView.leftAxis.gridLineWidth = 0
        chartView.rightAxis.drawAxisLineEnabled = false
        chartView.rightAxis.drawLabelsEnabled = false
        chartView.rightAxis.gridLineWidth = 0
        chartView.xAxis.enabled = false
        chartView.legend.enabled = false
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false
        
        // marker
        var marker = createMarker()
        marker.chartView = chartView
        chartView.marker = marker
        
        return chartView
    }()
    override func commonInit() {
        super.commonInit()
        stackView.alignment = .fill
        stackView.insertArrangedSubview(amountLabel, at: 0)
        stackView.insertArrangedSubview(changeLabel, at: 1)
        stackView.insertArrangedSubview(lineChartView.padding(.init(x: -10, y: 0)), at: 2)
    }
    
    func setUp(wallet: Wallet) {
        amountLabel.text = wallet.amountInUSD.toString(maximumFractionDigits: 2) + " US$"
        changeLabel.text = "\(wallet.price?.change24h?.value.toString(showPlus: true) ?? "") US$ (\((wallet.price?.change24h?.percentage * 100).toString(maximumFractionDigits: 2, showPlus: true)) %) 24 hrs"
    }
    
    private func createMarker() -> ValueByDateChartMarker {
        ValueByDateChartMarker(
            color: .textBlack,
            font: .systemFont(ofSize: 12),
            textColor: .textWhite,
            insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8)
        )
    }
}

extension WDVCSectionHeaderView {
    class ChartView: LineChartView, LazyView {
        func handleDataLoaded(_ prices: [PriceRecord]) {
            var x = 0
            let values = prices.map { price -> ChartDataEntry in
                x += 1
                return ChartDataEntry(x: Double(x), y: price.close, data: price.startTime)
            }
            
            let set1 = LineChartDataSet(entries: values)
            let gradientColors = [UIColor.clear.cgColor,
                                  UIColor.secondary.cgColor]
            let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!
            
            set1.fillAlpha = 1
            set1.fill = Fill(linearGradient: gradient, angle: 90)
            set1.drawFilledEnabled = true
            set1.drawCirclesEnabled = false
            set1.drawIconsEnabled = false
            
            set1.drawCirclesEnabled = false
            set1.lineWidth = 0
            set1.circleRadius = 0
            
            let data = LineChartData(dataSet: set1)
            data.setDrawValues(false)
            self.data = data
        }
        
        func handleError(_ error: Error) {
            // TODO: Error
            
        }
    }
}
