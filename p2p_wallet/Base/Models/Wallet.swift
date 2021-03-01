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
    var lamports: UInt64?
    var price: CurrentPrice?
    var decimals: Int?
    var indicatorColor: UIColor
    var isHidden = false
    
    // MARK: - Additional properties
    var isExpanded: Bool?
    var isProcessing: Bool?
    var amount: Double? {
        guard let decimals = decimals else {return nil}
        return lamports?.convertToBalance(decimals: decimals)
    }
    
    func pubkeyShort(numOfSymbolsRevealed: Int = 4) -> String {
        guard let pubkey = pubkey else {return ""}
        return pubkey.prefix(numOfSymbolsRevealed) + "..." + pubkey.suffix(numOfSymbolsRevealed)
    }
    
    var isBeingCreated: Bool?
    var creatingError: String?
    
    var backgroundColor: UIColor {
        // swiftlint:disable swiftgen_assets
        UIColor(named: symbol) ?? UIColor.coinGenericBackground
        // swiftlint:enable swiftgen_assets
    }
    
    var image: UIImage? {
        // swiftlint:disable swiftgen_assets
        UIImage(named: symbol)
        // swiftlint:enable swiftgen_assets
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
        self.lamports = programAccount.lamports
        self.pubkey = programAccount.pubkey
        self.decimals = programAccount.decimals
        // swiftlint:disable swiftgen_assets
        self.indicatorColor = UIColor(named: symbol) ?? UIColor.random
        // swiftlint:enable swiftgen_assets
        
    }
    
    static func placeholder(at index: Int) -> Wallet {
        Wallet(id: placeholderId(at: index), name: "<placeholder>", mintAddress: "placeholder-mintaddress", pubkey: "<pubkey>", symbol: "<PLHD\(index)>", lamports: nil, decimals: nil, indicatorColor: .clear)
    }
}

extension Array where Element == Wallet {
    var solWallet: Wallet? {
        first(where: {$0.symbol == "SOL"})
    }
}
