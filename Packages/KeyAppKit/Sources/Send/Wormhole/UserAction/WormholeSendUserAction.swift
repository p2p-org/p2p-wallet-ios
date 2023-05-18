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

    public var status: UserActionStatus

    /// Source token that will be taken and transferred to recipient.
    public let sourceToken: SolanaToken

    /// Recipient in Ethereum network
    public let recipient: String

    /// Transfer amount in crypto
    public let amount: CryptoAmount

    /// Transfer amount in fiat
    public let currencyAmount: CurrencyAmount?

    /// Fees
    public let fees: SendFees

    /// Solana transaction
    public let transaction: SendTransaction?

    public let createdDate: Date

    public var updatedDate: Date

    public init(
        sourceToken: SolanaToken,
        recipient: String,
        amount: CryptoAmount,
        currencyAmount: CurrencyAmount?,
        fees: SendFees,
        transaction: SendTransaction
    ) {
        id = transaction.message
        status = .pending
        createdDate = Date()
        updatedDate = createdDate

        self.sourceToken = sourceToken
        self.recipient = recipient
        self.amount = amount
        self.currencyAmount = currencyAmount
        self.fees = fees
        self.transaction = transaction
    }

    public init(sendStatus: WormholeSendStatus, solanaTokensService: SolanaTokensService) async throws {
        id = sendStatus.id

        switch sendStatus.status {
        case .failed, .expired, .canceled:
            status = .error(WormholeSendUserActionError.sendingFailure)
        case .pending, .inProgress:
            status = .processing
        case .completed:
            status = .ready
        }

        createdDate = sendStatus.created
        updatedDate = sendStatus.modified

        // Extract sending token
        let tokens = try await solanaTokensService.getTokensList()
        let token: SolanaToken

        switch sendStatus.amount.token {
        case .ethereum:
            throw WormholeSendUserActionError.parseError
        case let .solana(mint):
            if let mint {
                let matchedToken = tokens.first { token in
                    token.address == mint
                }

                guard let matchedToken else {
                    throw WormholeSendUserActionError.parseError
                }

                token = matchedToken
            } else {
                token = .nativeSolana
            }
        }

        sourceToken = token
        recipient = sendStatus.recipient
        amount = sendStatus.amount.asCryptoAmount
        currencyAmount = sendStatus.amount.asCurrencyAmount
        fees = sendStatus.fees
        transaction = nil
    }
}
