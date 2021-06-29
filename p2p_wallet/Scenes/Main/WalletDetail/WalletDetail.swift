//
//  WalletDetail.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation

protocol WalletDetailScenesFactory {
    func makeReceiveTokenViewController(tokenWalletPubkey: String?) -> ReceiveToken.ViewController?
    func makeSendTokenViewController(walletPubkey: String?, destinationAddress: String?) -> SendToken.ViewController
    func makeSwapTokenViewController(fromWallet wallet: Wallet?) -> SwapToken.ViewController
    func makeTokenSettingsViewController(pubkey: String) -> TokenSettingsViewController
    func makeTransactionInfoViewController(transaction: SolanaSDK.ParsedTransaction) -> TransactionInfoViewController
}

struct WalletDetail {
    enum NavigatableScene {
        case settings(walletPubkey: String)
        case send(wallet: Wallet)
        case receive(walletPubkey: String)
        case swap(fromWallet: Wallet)
        case transactionInfo(_ transaction: SolanaSDK.ParsedTransaction)
    }
}
