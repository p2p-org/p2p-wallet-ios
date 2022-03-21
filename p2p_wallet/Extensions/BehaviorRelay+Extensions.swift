//
//  BehaviorRelay+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 04/12/2020.
//

import Foundation
import RxCocoa

extension BehaviorRelay where Element: RangeReplaceableCollection {
    func insert(
        _ element: Element.Element,
        where condition: (Element.Element) throws -> Bool,
        shouldUpdate: Bool = false
    ) {
        var newArray = value
        guard let index = try? newArray.firstIndex(where: condition) else {
            newArray.append(element)
            accept(newArray)
            return
        }
        if shouldUpdate {
            newArray.remove(at: index)
            newArray.insert(element, at: index)
            accept(newArray)
        }
    }

    func removeAll(where condition: (Element.Element) throws -> Bool) {
        var newArray = value
        try? newArray.removeAll(where: condition)
        accept(newArray)
    }
}
