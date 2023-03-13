//
//  File.swift
//
//
//  Created by Giang Long Tran on 11.03.2023.
//

import Foundation

public struct Price: Hashable {
    /// ISO 4217 Currency code
    public let currencyCode: String

    /// Value of price
    public let value: Decimal?

    public init(currencyCode: String, value: Decimal?) {
        self.currencyCode = currencyCode
        self.value = value
    }
}
