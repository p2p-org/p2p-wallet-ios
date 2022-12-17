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
            .f2f2f7.withAlphaComponent(0.24),
            .f2f2f7.withAlphaComponent(0.48),
            .f2f2f7,
            .f2f2f7.withAlphaComponent(0.48),
            .f2f2f7.withAlphaComponent(0.24),
        ]
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

extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }
}
