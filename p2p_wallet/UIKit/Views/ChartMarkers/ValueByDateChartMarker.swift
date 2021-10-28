//
//  ValueByDateChartMarker.swift
//  p2p_wallet
//
//  Created by Chung Tran on 14/12/2020.
//

import Foundation
import Charts

class ValueByDateChartMarker: ChartMarker {
    override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        var string = entry.y.toString(autoSetMaximumFractionDigits: true) + " " + Defaults.fiat.symbol
        if let date = entry.data as? Date {
            string += "\n"
            string += date.string(withFormat: "dd MMM yyyy HH:mm:ss")
        }
        setLabel(string)
    }
}
