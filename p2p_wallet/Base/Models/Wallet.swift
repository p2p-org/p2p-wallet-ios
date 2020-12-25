//
//  Wallet.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation

// wrapper of 
struct Wallet: FiatConvertable {
    let id: String
    var name: String
    let mintAddress: String
    var pubkey: String?
    let symbol: String
    let icon: String?
    var lamports: UInt64?
    var price: CurrentPrice?
    var decimals: Int?
    
    // MARK: - Additional properties
    var isExpanded: Bool?
    var isProcessing: Bool?
    var amount: Double? {
        Double(lamports ?? 0) * pow(10, -Double(decimals ?? 0))
    }
    
    func pubkeyShort(numOfSymbolsRevealed: Int = 4) -> String {
        guard let pubkey = pubkey else {return ""}
        return "0x" + pubkey.prefix(numOfSymbolsRevealed) + "..." + pubkey.suffix(numOfSymbolsRevealed)
    }
}

extension Wallet: ListItemType {
    init(programAccount: SolanaSDK.Token) {
        self.id = programAccount.pubkey ?? ""
        var name = programAccount.name
        if let pubkey = programAccount.pubkey,
           let n = Defaults.walletName[pubkey]
        {
            name = n
        }
        self.name = name
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
