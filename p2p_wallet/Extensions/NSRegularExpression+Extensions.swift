//
//  NSRegularExpression+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/09/2021.
//

import Foundation

extension NSRegularExpression {
    static func bitcoinAddress(isTestnet: Bool) -> NSRegularExpression {
        try! NSRegularExpression(pattern: "^(\(isTestnet ? "tb1|": "")bc1|[13])[a-zA-HJ-NP-Z0-9]{25,39}$")
    }
}

extension String {
    func matches(oneOfRegexes regexes: NSRegularExpression...) -> Bool {
        regexes.contains(where: {$0.matches(self)})
    }
    
    func matches(allOfRegexes regexes: NSRegularExpression...) -> Bool {
        regexes.allSatisfy {$0.matches(self)}
    }
}
