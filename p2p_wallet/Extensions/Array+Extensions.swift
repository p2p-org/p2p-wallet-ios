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

extension Array where Element: UIColor {
    static var defaultLoaderGradientColors: [UIColor] {
        [
            .gray.withAlphaComponent(0.12),
            .gray.withAlphaComponent(0.24),
            .gray.withAlphaComponent(0.48),
            .gray.withAlphaComponent(0.24),
            .gray.withAlphaComponent(0.12)
        ]
    }
}
