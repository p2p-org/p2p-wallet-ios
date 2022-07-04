//
//  OrcaSwapV2.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/10/2021.
//

import Foundation
import RxCocoa
import RxSwift
import SolanaSwift

enum OrcaSwapV2 {
    enum NavigatableScene {
        case chooseSourceWallet(currentlySelectedWallet: Wallet?)
        case chooseDestinationWallet(
            currentlySelectedWallet: Wallet?,
            validMints: Set<String>,
            excludedSourceWalletPubkey: String?
        )
        case settings
        case confirmation
        case processTransaction(_ transaction: RawTransactionType)
        case info(title: String, description: String)
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
        case payingFeeWalletNotFound
        case notEnoughSOLToCoverFees
        case notEnoughBalanceToCoverFees
        case unknown
    }

    enum ActiveInputField {
        case source, destination, none
    }
}
