//
//  Wallet.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation

// wrapper of 
struct Wallet: ListItemType {
    let name: String
    let mintAddress: String
    let pubkey: String?
    let symbol: String
    let icon: String?
    var amount: Double? // In SOL
    var price: Price?
    
    static func placeholder(at index: Int) -> Wallet {
        Wallet(name: "placeholder", mintAddress: "placeholder-mintaddress", pubkey: "", symbol: "PLHD\(index)", icon: nil, amount: nil)
    }
}

extension Wallet {
    init(programAccount: SolanaSDK.Token) {
        self.name = programAccount.name
        self.mintAddress = programAccount.mintAddress
        self.symbol = programAccount.symbol
        self.icon = programAccount.icon
        self.amount = Double(programAccount.amount ?? 0) * 0.000000001
        self.pubkey = programAccount.pubkey
    }
}
