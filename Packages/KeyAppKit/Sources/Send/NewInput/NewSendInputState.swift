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

    public let userWallet: String
    public let recipient: String

    public let token: SolanaToken
    public let amount: UInt64
    public let feeSelectionMode: FeeSelectionMode
    public let configuration: TransferOptions
}

public struct NSendOutput: Hashable {
    public let transactionDetails: TransactionDetails
    public let transferAmounts: TransferAmounts
    public let fees: TransferFees
}
