//
//  Wallet.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation

// wrapper of 
struct Wallet {
    let name: String
    let mintAddress: String
    let pubkey: String?
    let symbol: String
    let icon: String?
    var amount: Double?
    var price: Price?
    var decimals: Int?
}

extension Wallet: ListItemType {
    init(programAccount: SolanaSDK.Token) {
        self.name = programAccount.name
        self.mintAddress = programAccount.mintAddress
        self.symbol = programAccount.symbol
        self.icon = programAccount.icon
        self.amount = Double(programAccount.amount ?? 0) * pow(10, -Double(programAccount.decimals ?? 0))
        self.pubkey = programAccount.pubkey
        self.decimals = programAccount.decimals
    }
    
    static func placeholder(at index: Int) -> Wallet {
        Wallet(name: "placeholder", mintAddress: "placeholder-mintaddress", pubkey: "pubkey", symbol: "PLHD\(index)", icon: nil, amount: nil, decimals: nil)
    }
}
