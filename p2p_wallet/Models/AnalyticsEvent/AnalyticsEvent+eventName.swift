//
//  AnalyticsEvent+RawRepresentable.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/06/2021.
//

import Foundation

extension AnalyticsEvent {
    /// eventName is snakeCased of event minus params, for example: firstInOpen(scene: String) becomes first_in_open
    var eventName: String? {
        var camelCasedText = "\(self)"
        if let index = "\(self)".firstIndex(of: "(") {
            camelCasedText = String(camelCasedText.prefix(upTo: index))
        }
        return camelCasedText.snakeCased()
    }
}

private extension String {
    func snakeCased() -> String? {
        let pattern = "([a-z0-9])([A-Z])"
        
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2").lowercased()
    }
}
