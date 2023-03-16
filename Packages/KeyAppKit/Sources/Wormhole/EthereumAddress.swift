//
//  File.swift
//
//
//  Created by Giang Long Tran on 01.03.2023.
//

import Foundation
import Web3

public enum EthereumAddressValidation {
    public static func validate(_ hex: String) -> Bool {
        if !hex.hasPrefix("0x") {
            return false
        }

        let address = try? EthereumAddress(hex: hex, eip55: false)
        return address != nil
    }
}
