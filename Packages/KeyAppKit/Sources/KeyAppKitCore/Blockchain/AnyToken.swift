//
//  AnyToken.swift
//
//
//  Created by Giang Long Tran on 24.03.2023.
//

import Foundation

/// Any token for easy converable
public protocol AnyToken {
    /// Token primary key
    var tokenPrimaryKey: String { get }

    /// Token symbol
    var symbol: String { get }

    /// Token full name
    var name: String { get }

    /// Decimal for token
    var decimals: UInt8 { get }
}
