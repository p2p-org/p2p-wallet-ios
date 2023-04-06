//
//  File.swift
//
//
//  Created by Giang Long Tran on 30.03.2023.
//

import BigInt
import FeeRelayerSwift
import Foundation
import KeyAppKitCore
import Wormhole

public struct WormholeSendInputBase: Equatable {
    public var solanaAccount: SolanaAccount

    public var availableAccounts: [SolanaAccount]

    public var amount: CryptoAmount

    public let recipient: String

    public init(
        solanaAccount: SolanaAccount,
        availableAccounts: [SolanaAccount],
        amount: CryptoAmount,
        recipient: String
    ) {
        self.solanaAccount = solanaAccount
        self.availableAccounts = availableAccounts
        self.amount = amount
        self.recipient = recipient
    }
}

public struct WormholeSendOutputBase: Equatable {
    public let transactions: SendTransaction?
    public let fees: SendFees

    public let feePayer: SolanaAccount?
    public let feePayerAmount: CryptoAmount?
    public let relayContext: RelayContext

    public init(
        feePayer: SolanaAccount?,
        feePayerAmount: CryptoAmount?,
        transactions: SendTransaction?,
        fees: SendFees,
        relayContext: RelayContext
    ) {
        self.feePayer = feePayer
        self.feePayerAmount = feePayerAmount
        self.transactions = transactions
        self.fees = fees
        self.relayContext = relayContext
    }

    public func calculateMaxInput(input: WormholeSendInputBase) -> CryptoAmount? {
        guard let feePayer, let feePayerAmount else {
            return nil
        }

        return input.solanaAccount.cryptoAmount

//        let minSOLBalance = CryptoAmount(
//            uint64: relayContext.minimumRelayAccountBalance,
//            token: SolanaToken.nativeSolana
//        )
//
//        if input.solanaAccount.data.isNativeSOL {
//            // Sending SOL
//
//            if feePayer.data.isNativeSOL {
//                // Paying fee in SOL
//
//                if input.availableAccounts.count == 1, input.availableAccounts.first?.data.isNativeSOL ?? false {
//                    // User only has SOL
//                    return input.amount - feePayerAmount
//                } else {
//                    // User has others tokens.
//                    return input.amount
//                }
//            } else {
//                // Paying fee in SPL
//                return input.amount
//            }
//
//        } else {
//            if input.solanaAccount.data.token.address == feePayer.data.token.address {
//                if input.availableAccounts.count == 1 {
//                    // User only has one token.
//                    return input.amount - feePayerAmount
//                } else {
//                    // User has others tokens.
//                    return input.amount
//                }
//            } else {
//                return input.amount
//            }
//
//            // Sending SPL Token
//        }
    }
}
