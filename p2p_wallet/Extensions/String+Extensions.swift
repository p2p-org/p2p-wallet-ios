//
//  String+Extensions.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/23/20.
//

import Foundation

extension String {
    var firstCharacter: String {
        String(prefix(1))
    }
    public var uppercaseFirst: String {
        firstCharacter.uppercased() + String(dropFirst())
    }
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }

    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}
