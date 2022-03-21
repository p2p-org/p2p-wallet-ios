//
//  Collection+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/07/2021.
//

import Foundation

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
