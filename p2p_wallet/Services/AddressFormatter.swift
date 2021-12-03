//
//  AddressFormatter.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 26.10.2021.
//

protocol AddressFormatterType: AnyObject {
    func shortAddress(of: String) -> String
}

final class AddressFormatter: AddressFormatterType {
    func shortAddress(of address: String) -> String {
        return address.prefix(4) + "..." + address.suffix(4)
    }
}
