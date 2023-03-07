//
//  File.swift
//
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Foundation
import Web3

/// Ethereum token structure
public struct EthereumERC20Token {
    internal let _address: EthereumAddress

    public var address: String { _address.hex(eip55: false) }
    public let name: String
    public let symbol: String
    public let decimals: UInt8
}
