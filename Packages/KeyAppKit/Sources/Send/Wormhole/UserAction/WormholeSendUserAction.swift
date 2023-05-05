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
    public var id: String { message }

    // Send ID
    public var message: String

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
        transaction: SendTransaction,
        relayContext: RelayContext
    ) {
        message = transaction.message
        status = .pending
        createdDate = Date()
        updatedDate = createdDate

        self.sourceToken = sourceToken
        self.price = price
        self.recipient = recipient
        self.amount = amount
        self.fees = fees
        self.transaction = transaction
        self.relayContext = relayContext
    }

//    public init(sendStatus: WormholeSendStatus, solanaTokensService: SolanaTokensService) async {
//        message = sendStatus.message
//
//        switch sendStatus.status {
//        case .failed, .expired, .canceled:
//            status = .error(WormholeSendUserActionError.sendingFailure)
//        case .pending, .inProgress:
//            status = .processing
//        case .completed:
//            status = .ready
//        }
//
//        createdDate = Date()
//        updatedDate = createdDate
//
//        sendStatus.amount.token
//        
//        sourceToken = sendStatus
//        price = price
//        recipient = recipient
//        amount = amount
//        fees = fees
//        payingFeeTokenAccount = payingFeeTokenAccount
//        totalFeesViaRelay = totalFeesViaRelay
//        transaction = transaction
//        relayContext = relayContext
//    }
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
