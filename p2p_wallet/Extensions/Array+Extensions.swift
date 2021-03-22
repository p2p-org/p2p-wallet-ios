//
//  Array+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/02/2021.
//

import Foundation

extension Array where Element: Equatable {
    mutating func appendIfNotExist(_ el: Element?) {
        if let el = el, !self.contains(el) {
            append(el)
        }
    }
}
