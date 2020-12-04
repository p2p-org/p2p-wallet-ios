//
//  Wallet.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation

// wrapper of 
struct Wallet {
    let id: String
    let name: String
    let mintAddress: String
    let pubkey: String?
    let symbol: String
    let icon: String?
    var lamports: UInt64?
    var price: Price?
    var decimals: Int?
    var amount: Double {
        Double(lamports ?? 0) * pow(10, -Double(decimals ?? 0))
    }
    
    var amountInUSD: Double {
        amount * PricesManager.bonfida.prices.value.first(where: {$0.from == symbol})?.value
    }
}

extension Wallet: ListItemType {
    init(programAccount: SolanaSDK.Token) {
        self.id = programAccount.pubkey ?? ""
        self.name = programAccount.name
        self.mintAddress = programAccount.mintAddress
        self.symbol = programAccount.symbol
        self.icon = programAccount.icon
        self.lamports = programAccount.amount
        self.pubkey = programAccount.pubkey
        self.decimals = programAccount.decimals
    }
    
    static func placeholder(at index: Int) -> Wallet {
        Wallet(id: placeholderId(at: index), name: "placeholder", mintAddress: "placeholder-mintaddress", pubkey: "pubkey", symbol: "PLHD\(index)", icon: nil, lamports: nil, decimals: nil)
    }
}
