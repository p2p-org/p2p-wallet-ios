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
import SolanaSwift
import Wormhole

public struct WormholeSendInputBase: Equatable {
    /// The authorizated user's key pair.
    public let keyPair: KeyPair

    /// Selected account for transfer.
    public var solanaAccount: SolanaAccount

    /// All available accounts that user owns.
    public var availableAccounts: [SolanaAccount]

    /// Transfer amount
    public var amount: CryptoAmount

    /// Recipient ethereum address.
    public let recipient: String

    public init(
        keyPair: KeyPair,
        solanaAccount: SolanaAccount,
        availableAccounts: [SolanaAccount],
        amount: CryptoAmount,
        recipient: String
    ) {
        self.keyPair = keyPair
        self.solanaAccount = solanaAccount
        self.availableAccounts = availableAccounts
        self.amount = amount
        self.recipient = recipient
    }
}

public struct WormholeSendOutputBase: Equatable {
    public let transactions: SendTransaction?
    public let fees: SendFees
    public let relayContext: RelayContext

    public init(
        transactions: SendTransaction?,
        fees: SendFees,
        relayContext: RelayContext
    ) {
        self.transactions = transactions
        self.fees = fees
        self.relayContext = relayContext
    }

    public func calculateMaxInput(input: WormholeSendInputBase) -> CryptoAmount? {
        if input.solanaAccount.data.token.isNative {
            // Transfer SOL
            let minAmount = CryptoAmount(
                uint64: relayContext.minimumRelayAccountBalance,
                token: SolanaToken.nativeSolana
            )

            return input.solanaAccount.cryptoAmount - minAmount
        } else {
            return input.solanaAccount.cryptoAmount
        }
    }
}
