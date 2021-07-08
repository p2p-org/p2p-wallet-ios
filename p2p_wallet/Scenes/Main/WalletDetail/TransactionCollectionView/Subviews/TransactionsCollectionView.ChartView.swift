//
//  TransactionsCollectionView.ChartView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/07/2021.
//

import Foundation
import Charts

extension TransactionsCollectionView {
    class ChartView: LineChartView, LazyView {
        init() {
            super.init(frame: .zero)
            configureForAutoLayout()
            autoSetDimension(.height, toSize: 257)
            
            chartDescription?.enabled = false
            leftAxis.drawAxisLineEnabled = false
            leftAxis.drawLabelsEnabled = false
            leftAxis.gridLineWidth = 0
            rightAxis.drawAxisLineEnabled = false
            rightAxis.drawLabelsEnabled = false
            rightAxis.gridLineWidth = 0
            xAxis.enabled = false
            legend.enabled = false
            pinchZoomEnabled = false
            doubleTapToZoomEnabled = false
            noDataText = L10n.noChartDataAvailable
            
            // marker
            let marker = createMarker()
            marker.chartView = self
            self.marker = marker
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func handleDataLoaded(_ prices: [PriceRecord]) {
            var x = 0
            let values = prices.map { price -> ChartDataEntry in
                x += 1
                return ChartDataEntry(x: Double(x), y: price.close, data: price.startTime)
            }
            
            let set1 = LineChartDataSet(entries: values)
            let gradientColors = [
                UIColor.h5887ff.withAlphaComponent(0).cgColor,
                UIColor.h5887ff.withAlphaComponent(1).cgColor
              ]
            let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: [0, 1])!
            
            set1.fillAlpha = 1
            set1.fill = Fill(linearGradient: gradient, angle: 90)
            set1.drawFilledEnabled = true
            set1.drawCirclesEnabled = false
            set1.drawIconsEnabled = false
            
            set1.drawCirclesEnabled = false
            set1.lineWidth = 1.5
            set1.setColor(.h5887ff)
            set1.circleRadius = 0
            
            let data = LineChartData(dataSet: set1)
            data.setDrawValues(false)
            self.data = data
            self.animate(xAxisDuration: 0.3)
        }
        
        func handleError(_ error: Error) {
            // TODO: Error
            
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
}
