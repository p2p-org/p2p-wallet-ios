//
//  String+Extensions.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/23/20.
//

import Foundation

extension Optional where Wrapped == String {
    public var orEmpty: String {
        self ?? ""
    }
    static func + (left: String?, right: String?) -> String {
        left.orEmpty + right.orEmpty
    }
    func toDouble() -> Double? {
        self == nil ? nil: Double(self!)
    }
}

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
    
    // swiftlint:disable swiftgen_strings
    func localized() -> String {
        NSLocalizedString(self, comment: "")
    }
    // swiftlint:enable swiftgen_strings
}

extension String {
    var double: Double? {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current // USA: Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        return formatter.number(from: self)?.doubleValue
    }
}
