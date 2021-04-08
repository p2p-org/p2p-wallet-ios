//
//  Wallet.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation

// wrapper of 
struct Wallet: FiatConvertable {
    private init(
        id: String,
        mintAddress: String,
        pubkey: String? = nil,
        symbol: String,
        lamports: UInt64? = nil,
        price: CurrentPrice? = nil,
        decimals: Int? = nil,
        isLiquidity: Bool,
        wrappedBy: String?,
        isExpanded: Bool? = nil,
        isProcessing: Bool? = nil,
        isBeingCreated: Bool? = nil,
        creatingError: String? = nil
    ) {
        self.id = id
        self.mintAddress = mintAddress
        self.pubkey = pubkey
        self.symbol = symbol
        self.lamports = lamports
        self.price = price
        self.decimals = decimals
        self.isLiquidity = isLiquidity
        self.wrappedBy = wrappedBy
        self.isExpanded = isExpanded
        self.isProcessing = isProcessing
        self.isBeingCreated = isBeingCreated
        self.creatingError = creatingError
        
        updateVisibility()
    }
    
    let id: String
    let mintAddress: String
    var pubkey: String?
    let symbol: String
    var lamports: UInt64?
    var price: CurrentPrice?
    var decimals: Int?
    let isLiquidity: Bool
    let wrappedBy: String?
    private var _isHidden = false
    private var _customName: String?
    
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
    
    var indicatorColor: UIColor {
        // swiftlint:disable swiftgen_assets
        UIColor(named: symbol) ?? UIColor.random
        // swiftlint:enable swiftgen_assets
    }
    
    var image: UIImage? {
        // swiftlint:disable swiftgen_assets
        UIImage(named: symbol)
        // swiftlint:enable swiftgen_assets
    }
    
    var isHidden: Bool {
        if symbol == "SOL" {return false}
        guard let pubkey = self.pubkey else {return false}
        if Defaults.hiddenWalletPubkey.contains(pubkey) {
            return true
        } else if Defaults.unhiddenWalletPubkey.contains(pubkey) {
            return false
        } else if Defaults.hideZeroBalances, amount == 0 {
            return true
        }
        return false
    }
    
    var name: String {
        guard let pubkey = pubkey else {return symbol}
        return Defaults.walletName[pubkey] ?? symbol
    }
    
    mutating func updateVisibility() {
        _isHidden = isHidden
    }
    
    mutating func setName(_ name: String) {
        _customName = name
    }
    
    var description: String {
        if symbol == "SOL" {
            return "Solana"
        }
        if let wrappedBy = self.wrappedBy {
            return L10n.wrappedBy(symbol, wrappedBy)
        }
        return symbol
    }
    
    static func createSOLWallet(pubkey: String?, lamports: UInt64, price: CurrentPrice?) -> Wallet {
        Wallet(
            id: pubkey ?? "SOL",
            mintAddress: "",
            pubkey: pubkey,
            symbol: "SOL",
            lamports: lamports,
            price: price,
            decimals: 9,
            isLiquidity: false,
            wrappedBy: nil
        )
    }
}

extension Wallet: ListItemType {
    init(programAccount: SolanaSDK.Token) {
        self.id = programAccount.pubkey ?? ""
        self.mintAddress = programAccount.mintAddress
        self.symbol = programAccount.symbol
        self.lamports = programAccount.lamports
        self.pubkey = programAccount.pubkey
        self.decimals = programAccount.decimals
        self.isLiquidity = programAccount.isLiquidity
        self.wrappedBy = programAccount.wrappedBy
    }
    
    static func placeholder(at index: Int) -> Wallet {
        Wallet(id: placeholderId(at: index), mintAddress: "placeholder-mintaddress", pubkey: "<pubkey>", symbol: "<PLHD\(index)>", lamports: nil, decimals: nil, isLiquidity: false, wrappedBy: nil)
    }
}

extension Array where Element == Wallet {
    var solWallet: Wallet? {
        first(where: {$0.symbol == "SOL"})
    }
}
