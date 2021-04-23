//
//  SolanaSDK.Wallet+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/04/2021.
//

import Foundation

typealias Wallet = SolanaSDK.Wallet

struct SolanaWalletUserInfo: Hashable {
    var price: CurrentPrice?
    var _isHidden = false
    var isProcessing: Bool?
    var _customName: String?
    var isBeingCreated: Bool?
    var creatingError: String?
}

extension SolanaSDK.Wallet {
    var name: String {
        guard let pubkey = pubkey else {return token.symbol}
        return Defaults.walletName[pubkey] ?? token.symbol
    }
    
    var mintAddress: String {
        token.address
    }
    
    var isHidden: Bool {
        if token.symbol == "SOL" {return false}
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
    
    var isBeingCreated: Bool? {
        get {
            getParsedUserInfo().isBeingCreated
        }
        set {
            var userInfo = getParsedUserInfo()
            userInfo.isBeingCreated = newValue
            self.userInfo = userInfo
        }
    }
    
    var creatingError: String? {
        get {
            getParsedUserInfo().creatingError
        }
        set {
            var userInfo = getParsedUserInfo()
            userInfo.creatingError = newValue
            self.userInfo = userInfo
        }
    }
    
    var isProcessing: Bool? {
        get {
            getParsedUserInfo().isProcessing
        }
        set {
            var userInfo = getParsedUserInfo()
            userInfo.isProcessing = newValue
            self.userInfo = userInfo
        }
    }
    
    var price: CurrentPrice? {
        get {
            getParsedUserInfo().price
        }
        set {
            var userInfo = getParsedUserInfo()
            userInfo.price = newValue
            self.userInfo = userInfo
        }
    }
    
    mutating func updateVisibility() {
        var userInfo = getParsedUserInfo()
        userInfo._isHidden = isHidden
        self.userInfo = userInfo
    }
    
    mutating func setName(_ name: String) {
        var userInfo = getParsedUserInfo()
        userInfo._customName = name
        self.userInfo = userInfo
    }
    
    func getParsedUserInfo() -> SolanaWalletUserInfo {
        userInfo as? SolanaWalletUserInfo ?? SolanaWalletUserInfo()
    }
}

extension Wallet: FiatConvertable {
    var symbol: String {
        token.symbol
    }
}
