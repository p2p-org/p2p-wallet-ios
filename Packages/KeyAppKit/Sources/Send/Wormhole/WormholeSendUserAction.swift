//
//  File.swift
//
//
//  Created by Giang Long Tran on 05.04.2023.
//

import FeeRelayerSwift
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Wormhole

public struct WormholeSendUserAction: UserAction {
    public var id: String

    public var trackingKey: Set<String> {
        Set([id, transaction.message].compactMap { $0 })
    }

    public var status: UserActionStatus

    /// Source token that will be taken and transferred to recipient.
    public let sourceToken: SolanaToken

    /// Fixed token price at submitted moment.
    public let price: TokenPrice?

    /// Recipient in Ethereum network
    public let recipient: String

    /// Transfer amount
    public let amount: CryptoAmount

    /// Fees
    public let fees: SendFees

    /// Paying account
    public let payingFeeTokenAccount: FeeRelayerSwift.TokenAccount

    /// Total fees when using relay service
    public let totalFeesViaRelay: CryptoAmount?

    /// Solana transaction
    public let transaction: SendTransaction

    /// Relay context
    public let relayContext: RelayContext

    public let createdDate: Date

    public var updatedDate: Date

    public init(
        sourceToken: SolanaToken,
        price: TokenPrice?,
        recipient: String,
        amount: CryptoAmount,
        fees: SendFees,
        payingFeeTokenAccount: FeeRelayerSwift.TokenAccount,
        totalFeesViaRelay: CryptoAmount?,
        transaction: SendTransaction,
        relayContext: RelayContext
    ) {
        id = UUID().uuidString
        status = .pending
        createdDate = Date()
        updatedDate = createdDate

        self.sourceToken = sourceToken
        self.price = price
        self.recipient = recipient
        self.amount = amount
        self.fees = fees
        self.payingFeeTokenAccount = payingFeeTokenAccount
        self.totalFeesViaRelay = totalFeesViaRelay
        self.transaction = transaction
        self.relayContext = relayContext
    }
}

public extension WormholeSendUserAction {
    /// Transferred amount in fiat.
    var currencyAmount: CurrencyAmount? {
        guard let price = price else {
            return nil
        }

        return try? amount.toFiatAmount(price: price)
    }
}
