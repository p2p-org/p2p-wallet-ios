//
//  ValueByDateChartMarker.swift
//  p2p_wallet
//
//  Created by Chung Tran on 14/12/2020.
//

import Charts
import Foundation

class ValueByDateChartMarker: ChartMarker {
    override func refreshContent(entry: ChartDataEntry, highlight _: Highlight) {
        var string = entry.y.toString(autoSetMaximumFractionDigits: true) + " " + Defaults.fiat.symbol
        if let date = entry.data as? Date {
            string += "\n"
            string += date.string(withFormat: "dd MMM yyyy HH:mm:ss")
        }
        setLabel(string)
    }
}
