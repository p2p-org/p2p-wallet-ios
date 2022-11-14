//
//  LockAndMint+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/06/2022.
//

import Foundation
import RenVMSwift
import SolanaSwift

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

extension LockAndMint.ProcessingTx {
    var statusString: String? {
        switch state {
        case let .ignored(error):
            return error.errorDescription
        case .minted:
            return L10n.successfullyMintedRenBTC(
                tx.value.convertToBalance(decimals: 8)
                    .toString(maximumFractionDigits: 9)
            )
        case .submited:
            return L10n.minting
        case .confirmed:
            return L10n.submittingToRenVM
        case .confirming:
            return L10n.waitingForDepositConfirmation + " \(tx.vout)/\(Self.maxVote)"
        }
    }

    var value: Double {
        tx.value.convertToBalance(decimals: 8)
    }
}

extension LockAndMint.ProcessingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .insufficientFund(expected, got):
            return L10n.error(L10n.amountIsTooSmallExpectedGot(expected.convertToBalance(decimals: Token.renBTC.decimals), got.convertToBalance(decimals: Token.renBTC.decimals)))
        case let .other(message):
            return L10n.error(message.localized())
        }
    }
}
