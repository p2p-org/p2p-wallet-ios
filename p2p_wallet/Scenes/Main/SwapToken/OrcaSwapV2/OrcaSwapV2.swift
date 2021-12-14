//
//  OrcaSwapV2.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/10/2021.
//

import Foundation
import RxCocoa
import RxSwift

enum OrcaSwapV2 {
    enum NavigatableScene {
        case chooseSourceWallet
        case chooseDestinationWallet(validMints: Set<String>, excludedSourceWalletPubkey: String?)
        case settings
        case chooseSlippage
        case choosePayFeeToken(tokenName: String?)
        case processTransaction(request: Single<ProcessTransactionResponseType>, transactionType: ProcessTransaction.TransactionType)
        case back
    }
    
    enum VerificationError: String {
        case swappingIsNotAvailable
        case sourceWalletIsEmpty
        case destinationWalletIsEmpty
        case canNotSwapToItSelf
        case tradablePoolsPairsNotLoaded
        case tradingPairNotSupported
        case feesIsBeingCalculated
        case couldNotCalculatingFees
        case inputAmountIsEmpty
        case inputAmountIsNotValid
        case insufficientFunds
        case estimatedAmountIsNotValid
        case bestPoolsPairsIsEmpty
        case slippageIsNotValid
        case nativeWalletNotFound
        case notEnoughSOLToCoverFees
        case notEnoughBalanceToCoverFees
        case unknown
    }
}
