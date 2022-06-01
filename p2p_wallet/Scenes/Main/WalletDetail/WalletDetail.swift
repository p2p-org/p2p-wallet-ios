//
//  WalletDetail.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation
import SolanaSwift

enum WalletDetail {
    enum NavigatableScene {
        case settings(walletPubkey: String)
        case buy(tokens: Buy.CryptoCurrency)
        case send(wallet: Wallet)
        case receive(walletPubkey: String)
        case swap(fromWallet: Wallet)
        case transactionInfo(_ transaction: ParsedTransaction)
    }
}
