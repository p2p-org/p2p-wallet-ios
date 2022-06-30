//
//  LockAndMint+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/06/2022.
//

import Foundation
import RenVMSwift

extension LockAndMint {
    static var keyForSession: String {
        "renVMSession"
    }

    static var keyForGatewayAddress: String {
        "renVMGatewayAddress"
    }

    static var keyForProcessingTransactions: String {
        "renVMProcessingTxs"
    }
}

public extension LockAndMint.ProcessingTx {
    var statusString: String? {
        if mintedAt != nil {
            return L10n.successfullyMintedRenBTC(
                tx.value.convertToBalance(decimals: 8)
                    .toString(maximumFractionDigits: 9)
            )
        }

        if submitedAt != nil {
            return L10n.minting
        }

        if confirmedAt != nil {
            return L10n.submittingToRenVM
        }

        if receivedAt != nil {
            return L10n.waitingForDepositConfirmation + " \(tx.vout)/\(Self.maxVote)"
        }

        return nil
    }

    var value: Double {
        tx.value.convertToBalance(decimals: 8)
    }
}
