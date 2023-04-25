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

extension Array where Element: Hashable {
    var unique: [Element] {
        var buffer = [Element]()
        var added = Set<Element>()
        for elem in self {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        return buffer
    }
}
