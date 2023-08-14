//
//  File.swift
//
//
//  Created by Giang Long Tran on 07.08.2023.
//

import Foundation
import KeyAppKitCore
import KeyAppStateMachine

public enum NSendInputState: Hashable, State {
    case initialising
    case calculating(input: NSendInput)
    case ready(input: NSendInput, output: NSendOutput)
    case error(input: NSendInput, output: NSendOutput?, error: NSendError)

    public var input: NSendInput? {
        switch self {
        case let .calculating(input):
            return input
        case let .error(input, _, _):
            return input
        case let .ready(input, _):
            return input
        default:
            return nil
        }
    }

    public var output: NSendOutput? {
        switch self {
        case let .error(_, output, _):
            return output
        case let .ready(_, output):
            return output
        default:
            return nil
        }
    }
}

public enum NSendError: Hashable {
    case noAmount
    case insufficientAmount
    case server(code: Int, message: String)
    case unknown(String)
}

public struct NSendInput: Hashable {
    public enum FeeSelectionMode: Hashable {
        public enum Strategy: Hashable {
            case sameToken
            case solana
            case tokenWithHighestBalance
        }

        case auto(Strategy)
        case manual(SolanaToken)
    }

    public var owner: String
    public var account: SolanaAccount
    public let recipient: String
    public var amount: UInt64
    public let feeSelectionMode: FeeSelectionMode
    public let configuration: TransferOptions

    public init(
        owner: String,
        account: SolanaAccount,
        recipient: String,
        amount: UInt64,
        feeSelectionMode: FeeSelectionMode,
        configuration: TransferOptions
    ) {
        self.owner = owner
        self.account = account
        self.recipient = recipient
        self.amount = amount
        self.feeSelectionMode = feeSelectionMode
        self.configuration = configuration
    }
}

public extension NSendInput {
    var tokenAmount: CryptoAmount {
        CryptoAmount(uint64: amount, token: account.token)
    }
}

public struct NSendOutput: Hashable {
    public let transactionDetails: TransactionDetails
    public let transferAmounts: TransferAmounts
    public let fees: TransferFees
}
