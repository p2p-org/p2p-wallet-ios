//
//  RenBTCReceivingStatuses.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/10/2021.
//

import Foundation
import RxCocoa

struct RenBTCReceivingStatuses {
    enum NavigatableScene {
        case detail(txid: String)
    }
    
    struct Record: Hashable {
        enum Status: String, Equatable {
            case waitingForConfirmation, confirmed, submitted, minted
        }
        
        let txid: String
        let status: Status
        let time: Date
        var vout: UInt64?
        var amount: UInt64?
        
        var stringValue: String {
            switch status {
            case .waitingForConfirmation:
                return L10n.waitingForDepositConfirmation
            case .confirmed:
                return L10n.submittingToRenVM
            case .submitted:
                return L10n.minting
            case .minted:
                return L10n.successfullyMintedRenBTC(
                    (amount ?? 0).convertToBalance(decimals: 8)
                        .toString(maximumFractionDigits: 9)
                )
            }
        }
    }
}
