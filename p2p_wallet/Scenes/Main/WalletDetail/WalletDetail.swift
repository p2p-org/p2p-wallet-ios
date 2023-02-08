//
//  WalletDetail.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation
import SolanaSwift
import TransactionParser

enum WalletDetail {
    enum NavigatableScene {
        case buy(tokens: Buy.CryptoCurrency)
        case send(wallet: Wallet)
        case receive(walletPubkey: String)
        case swap(fromWallet: Wallet)
        case cashOut
        case transactionInfo(_ transaction: ParsedTransaction)
    }
}
