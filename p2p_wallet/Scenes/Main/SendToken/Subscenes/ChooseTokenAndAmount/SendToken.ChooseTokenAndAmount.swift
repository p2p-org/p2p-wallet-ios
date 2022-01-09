//
//  SendToken.ChooseTokenAndAmount.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation
import RxCocoa

extension SendToken {
    enum ChooseTokenAndAmount {
        enum NavigatableScene {
            case chooseWallet
            case backToConfirmation // available only when viewModel.showAfterConfirmation = true
            case invalidTokenForSelectedNetworkAlert
        }
        
        enum CurrencyMode {
            case token, fiat
        }
        
        enum Error: String {
            case loadingIsNotCompleted
            case destinationWalletIsMissing
            case invalidAmount
            case insufficientFunds
            
            var buttonSuggestion: String? {
                switch self {
                case .loadingIsNotCompleted:
                    return L10n.loading
                case .destinationWalletIsMissing:
                    return L10n.chooseDestinationWallet
                case .invalidAmount:
                    return L10n.enterTheAmountToProceed
                case .insufficientFunds:
                    return L10n.insufficientFunds
                }
            }
        }
    }
}
