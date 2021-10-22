//
//  WalletDetail.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation

struct WalletDetail {
    enum NavigatableScene {
        case settings(walletPubkey: String)
        case buy(tokens: BuyToken.CryptoCurrency)
        case send(wallet: Wallet)
        case receive(walletPubkey: String)
        case swap(fromWallet: Wallet)
        case transactionInfo(_ transaction: SolanaSDK.ParsedTransaction)
    }
}
