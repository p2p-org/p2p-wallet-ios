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
    var wallet: Wallet?
    
    lazy var amountLabel = UILabel(text: "$120,00", textSize: 27, weight: .bold)
    lazy var tokenCountLabel = UILabel(text: "0 SOL", textSize: 15, textColor: .secondary)
    lazy var changeLabel = UILabel(textColor: .attentionGreen)
    lazy var lineChartView = ChartView()
    lazy var chartPicker: HorizontalPicker = {
        let chartPicker = HorizontalPicker(forAutoLayout: ())
        chartPicker.labels = Period.allCases.map {$0.rawValue.localized().uppercaseFirst}
        chartPicker.selectedIndex = Period.allCases.firstIndex(where: {$0 == .day})!
        return chartPicker
    }()
    lazy var walletAddressLabel = UILabel(text: L10n.walletAddress, textSize: 13, weight: .medium, textColor: .secondary)
    lazy var pubkeyLabel = UILabel(textSize: 15, weight: .medium)
    
    var scanQrCodeAction: CocoaAction?
    
    override func commonInit() {
        super.commonInit()
        stackView.alignment = .fill
        
        stackView.insertArrangedSubviews([
            amountLabel.padding(.init(x: 20, y: 0)),
            
            UIView.row([
                tokenCountLabel,
                changeLabel
            ]).padding(.init(x: 20, y: 0)),
            
            .separator(height: 2, color: .separator),
            
            lineChartView.padding(.init(x: -10, y: 0)),
            
            .separator(height: 1, color: .separator),
            
            chartPicker.padding(.init(x: 20, y: 0)),
            
            UIView.row([
                UIView.col([
                    walletAddressLabel,
                    pubkeyLabel
                ])
                    .with(spacing: 5)
                    .onTap(self, action: #selector(buttonCopyToClipboardDidTouch)),
                UIImageView(width: 24.75, height: 24.75, image: .scanQr2, tintColor: .h5887ff)
                    .onTap(self, action: #selector(buttonScanQrCodeDidTouch))
            ])
                .with(spacing: 20, alignment: .center, distribution: .fill)
                .padding(.init(x: 16, y: 10), backgroundColor: UIColor.a3a5ba.withAlphaComponent(0.1), cornerRadius: 12)
                .padding(.init(x: 20, y: 0))
        ], at: 0, withCustomSpacings: [10, 16, 0, 0, 10, 20, 40])
        
        // initial setups
        headerLabel.font = .systemFont(ofSize: 21, weight: .semibold)
    }
    
    func setUp(wallet: Wallet) {
        self.wallet = wallet
        let usdAmount = String(format: "%.02f", wallet.amountInUSD)
        amountLabel.text = "$ " + usdAmount
        tokenCountLabel.text = "\(wallet.symbol) \(wallet.amount.toString(maximumFractionDigits: 9))"
        changeLabel.text = "\(wallet.price?.change24h?.percentage?.toString(maximumFractionDigits: 2, showPlus: true) ?? "")% \(L10n._24Hours)"
        
        if wallet.price?.change24h?.percentage >= 0 {
            changeLabel.textColor = .attentionGreen
        } else {
            changeLabel.textColor = .red
        }
        pubkeyLabel.text = wallet.pubkey
    }
    
    @objc private func buttonScanQrCodeDidTouch() {
        scanQrCodeAction?.execute()
    }
    
    @objc private func buttonCopyToClipboardDidTouch() {
        UIApplication.shared.copyToClipboard(wallet?.pubkey, alert: false)
        
        walletAddressLabel.text = L10n.addressCopied
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.walletAddressLabel.text = L10n.walletAddress
        }
    }
}

extension WDVCSectionHeaderView {
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
