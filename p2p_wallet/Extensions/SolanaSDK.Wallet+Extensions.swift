//
//  Wallet+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/04/2021.
//

import Foundation
import SolanaPricesAPIs
import SolanaSwift

struct SolanaWalletUserInfo: Hashable {
    var price: CurrentPrice?
    var _isHidden = false
    var isProcessing: Bool?
    var _customName: String?
    var isBeingCreated: Bool?
    var creatingError: String?
}

extension Wallet {
    var name: String {
        guard let pubkey = pubkey else { return token.symbol }
        return Defaults.walletName[pubkey] ?? token.symbol
    }

    var mintAddress: String {
        token.address
    }

    var isHidden: Bool {
        if token.isNativeSOL { return false }
        guard let pubkey = pubkey else { return false }
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

    var priceInCurrentFiat: Double? {
        price?.value
    }

    var amountInCurrentFiat: Double {
        amount * priceInCurrentFiat
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

    mutating func updateBalance(diff: Double) {
        guard diff != 0 else { return }

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

    mutating func increaseBalance(diffInLamports: Lamports) {
        let currentBalance = lamports ?? 0
        lamports = currentBalance + diffInLamports
    }

    mutating func decreaseBalance(diffInLamports: Lamports) {
        let currentBalance = lamports ?? 0
        if currentBalance >= diffInLamports {
            lamports = currentBalance - diffInLamports
        } else {
            lamports = 0
        }
    }
}
