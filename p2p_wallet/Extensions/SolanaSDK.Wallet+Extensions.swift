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
        if token.isNativeSOL {return false}
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
    
    var priceInCurrentFiat: Double? {
        price?.value
    }
    
    var amountInCurrentFiat: Double {
        amount * priceInCurrentFiat
    }
        
    func getParsedUserInfo() -> SolanaWalletUserInfo {
        userInfo as? SolanaWalletUserInfo ?? SolanaWalletUserInfo()
    }
    
    mutating func updateBalance(diff: Double) {
        guard diff != 0 else {return}
        
        let currentBalance = lamports ?? 0
        let reduction = abs(diff).toLamport(decimals: token.decimals)
        
        if diff > 0 {
            lamports = currentBalance + reduction
        } else {
            if currentBalance >= reduction {
                lamports = currentBalance - reduction
            } else {
                lamports = 0
            }
        }
    }
    
    mutating func increaseBalance(diffInLamports: SolanaSDK.Lamports) {
        let currentBalance = lamports ?? 0
        lamports = currentBalance + diffInLamports
    }
    
    mutating func decreaseBalance(diffInLamports: SolanaSDK.Lamports) {
        let currentBalance = lamports ?? 0
        if currentBalance >= diffInLamports {
            lamports = currentBalance - diffInLamports
        } else {
            lamports = 0
        }
    }
}
