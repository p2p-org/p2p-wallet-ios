//
//  Recipient.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 21.10.2021.
//

struct Recipient: Hashable {
    let address: String
    let shortAddress: String
    let name: String?
    let hasNoFunds: Bool
}
