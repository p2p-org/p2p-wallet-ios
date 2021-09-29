//
//  WalletDetail.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation

protocol WalletDetailScenesFactory {
    func makeBuyTokenViewController(token: BuyToken.CryptoCurrency) throws -> UIViewController
    func makeReceiveTokenViewController(tokenWalletPubkey: String?) -> ReceiveToken.ViewController?
    func makeSendTokenViewController(walletPubkey: String?, destinationAddress: String?) -> SendToken.ViewController
    func makeSwapTokenViewController(provider: SwapProvider, fromWallet wallet: Wallet?) -> CustomPresentableViewController
    func makeTokenSettingsViewController(pubkey: String) -> TokenSettingsViewController
    func makeTransactionInfoViewController(transaction: SolanaSDK.ParsedTransaction) -> TransactionInfoViewController
}

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
