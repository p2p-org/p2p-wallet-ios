//
//  SwapToken.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/06/2021.
//

import Foundation
import RxSwift

struct SwapToken {
    enum NavigatableScene {
        case chooseSourceWallet
        case chooseDestinationWallet(validMints: Set<String>, excludedSourceWalletPubkey: String?)
        case chooseSlippage
        case processTransaction(request: Single<SolanaSDK.TransactionID>, transactionType: ProcessTransaction.TransactionType)
    }
}
