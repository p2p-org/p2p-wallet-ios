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
        var string = entry.y.toString(maximumFractionDigits: 4)
        if let date = entry.data as? Date {
            string += "\n"
            string += date.string(withFormat: "dd MMM yyyy")
        }
        setLabel(string)
    }
}
