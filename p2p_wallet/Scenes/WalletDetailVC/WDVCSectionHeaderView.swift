//
//  WDVCSectionHeaderView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation
import Charts
import Action

class WDVCSectionHeaderView: SectionHeaderView {
    lazy var amountLabel = UILabel(text: "$120,00", textSize: 25, weight: .semibold, textColor: .textBlack, textAlignment: .center)
    lazy var tokenCountLabel = UILabel(text: "0 SOL", textSize: 15, textColor: .secondary, textAlignment: .center)
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
    lazy var chartPicker: HorizontalPicker = {
        let chartPicker = HorizontalPicker(forAutoLayout: ())
        chartPicker.labels = Period.allCases.map {$0.rawValue.localized().uppercaseFirst}
        chartPicker.selectedIndex = Period.allCases.firstIndex(where: {$0 == .day})!
        return chartPicker
    }()
    lazy var pubkeyLabel = UILabel(textSize: 13, textColor: .secondary)
    
    var scanQrCodeAction: CocoaAction?
    
    override func commonInit() {
        super.commonInit()
        stackView.alignment = .fill
        stackView.insertArrangedSubview(amountLabel, at: 0)
        stackView.insertArrangedSubview(tokenCountLabel, at: 1)
        stackView.insertArrangedSubview(lineChartView.padding(.init(x: -10, y: 0)), at: 2)
        
        let separator = UIView.separator(height: 1, color: UIColor.textBlack.withAlphaComponent(0.1))
        stackView.insertArrangedSubview(separator, at: 3)
        stackView.insertArrangedSubview(chartPicker, at: 4)
        
        let walletAddressView: UIView = {
            let view = UIView(backgroundColor: .textWhite, cornerRadius: 16)
            let separator = UIView(width: 1, backgroundColor: UIColor.textBlack.withAlphaComponent(0.1))
            view.row([
                    UIView.col([
                        UILabel(text: L10n.walletAddress, textSize: 13, weight: .bold),
                        pubkeyLabel
                    ]).padding(UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 0)),
                    separator,
                    UIImageView(width: 24.75, height: 24.75, image: .copyToClipboard, tintColor: .secondary)
                        .onTap(self, action: #selector(buttonScanQrCodeDidTouch)),
                    UIView.spacer
                ])
                .with(spacing: 16, alignment: .center, distribution: .fill)
            separator.heightAnchor.constraint(equalTo: view.heightAnchor)
                .isActive = true
            return view
        }()
        
        stackView.insertArrangedSubview(walletAddressView.padding(.init(x: 16, y: 0)), at: 5)
        
        stackView.setCustomSpacing(5, after: amountLabel)
        stackView.setCustomSpacing(0, after: tokenCountLabel)
        stackView.setCustomSpacing(16, after: separator)
        stackView.setCustomSpacing(16, after: chartPicker)
        stackView.setCustomSpacing(30, after: walletAddressView.wrapper!)
        
        // initial setups
        headerLabel.font = .systemFont(ofSize: 21, weight: .semibold)
    }
    
    func setUp(wallet: Wallet) {
        amountLabel.text = wallet.amountInUSD.toString(maximumFractionDigits: 2) + " US$"
        tokenCountLabel.text = "\(wallet.amount.toString(maximumFractionDigits: 9)) \(wallet.symbol)"
        pubkeyLabel.text = wallet.pubkey
    }
    
    private func createMarker() -> ValueByDateChartMarker {
        ValueByDateChartMarker(
            color: .textBlack,
            font: .systemFont(ofSize: 12),
            textColor: .textWhite,
            insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8)
        )
    }
    
    @objc private func buttonScanQrCodeDidTouch() {
//        scanQrCodeAction?.execute()
        UIApplication.shared.copyToClipboard(pubkeyLabel.text)
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
            self.animate(xAxisDuration: 0.3)
        }
        
        func handleError(_ error: Error) {
            // TODO: Error
            
        }
    }
}
