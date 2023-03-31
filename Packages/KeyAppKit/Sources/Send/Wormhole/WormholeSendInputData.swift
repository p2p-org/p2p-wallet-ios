//
//  File.swift
//
//
//  Created by Giang Long Tran on 30.03.2023.
//

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
    public let feePayer: SolanaAccount?
    public let transactions: SendTransaction?
    public let fees: SendFees

    public init(feePayer: SolanaAccount?, transactions: SendTransaction?, fees: SendFees) {
        self.feePayer = feePayer
        self.transactions = transactions
        self.fees = fees
    }
}
