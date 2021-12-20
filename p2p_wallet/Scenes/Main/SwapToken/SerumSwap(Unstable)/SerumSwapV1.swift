//
//  SwapToken.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/08/2021.
//

import Foundation
import RxSwift
import RxCocoa

struct SerumSwapV1 {
    enum NavigatableScene {
        case chooseSourceWallet
        case chooseDestinationWallet
        case settings
        case chooseSlippage
        case swapFees
        case processTransaction(request: Single<ProcessTransactionResponseType>, transactionType: ProcessTransaction.TransactionType)
    }
}

protocol SwapTokenScenesFactory {
    func makeChooseWalletViewController(
        title: String?,
        customFilter: ((Wallet) -> Bool)?, 
        showOtherWallets: Bool,
        selectedWallet: Wallet?,
        handler: WalletDidSelectHandler
    ) -> ChooseWallet.ViewController
    func makeProcessTransactionViewController(transactionType: ProcessTransaction.TransactionType, request: Single<ProcessTransactionResponseType>) -> ProcessTransaction.ViewController
}
