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
    case network(description: String)
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

    public let userWallet: SolanaAccount
    public let recipient: String

    public let token: SolanaToken
    public var amount: UInt64
    public let feeSelectionMode: FeeSelectionMode
    public let configuration: TransferOptions

    public init(
        userWallet: SolanaAccount,
        recipient: String,
        token: SolanaToken,
        amount: UInt64,
        feeSelectionMode: FeeSelectionMode,
        configuration: TransferOptions
    ) {
        self.userWallet = userWallet
        self.recipient = recipient
        self.token = token
        self.amount = amount
        self.feeSelectionMode = feeSelectionMode
        self.configuration = configuration
    }
}

public extension NSendInput {
    var tokenAmount: CryptoAmount {
        CryptoAmount(uint64: amount, token: userWallet.token)
    }
}

public struct NSendOutput: Hashable {
    public let transactionDetails: TransactionDetails
    public let transferAmounts: TransferAmounts
    public let fees: TransferFees
}
