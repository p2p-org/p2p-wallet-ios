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
    var indicatorColor: UIColor {
        // swiftlint:disable swiftgen_assets
        UIColor(named: token.symbol) ?? .random
        // swiftlint:enable swiftgen_assets
    }
    
    var image: UIImage? {
        // swiftlint:disable swiftgen_assets
        UIImage(named: token.symbol)
        // swiftlint:enable swiftgen_assets
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
    
    var name: String {
        guard let pubkey = pubkey else {return token.symbol}
        return Defaults.walletName[pubkey] ?? token.symbol
    }
    
    mutating func updateVisibility() {
        var userInfo = self.userInfo as? SolanaWalletUserInfo
        userInfo?._isHidden = isHidden
        self.userInfo = userInfo
    }
    
    mutating func setName(_ name: String) {
        var userInfo = self.userInfo as? SolanaWalletUserInfo
        userInfo?._customName = name
        self.userInfo = userInfo
    }
    
    // TODO: - Wrapped by
//    var description: String {
//        if symbol == "SOL" {
//            return "Solana"
//        }
//        if let wrappedBy = self.wrappedBy {
//            return L10n.wrappedBy(symbol, wrappedBy)
//        }
//        return symbol
//    }
}

