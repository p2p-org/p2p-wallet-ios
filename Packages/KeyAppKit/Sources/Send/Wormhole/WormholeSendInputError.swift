//
//  File.swift
//
//
//  Created by Giang Long Tran on 30.03.2023.
//

import Foundation

public enum WormholeSendInputError: Error, Equatable {
    case calculationFeeFailure

    case calculationFeePayerFailure

    case getTransferTransactionsFailure

    case insufficientInputAmount

    case maxAmountReached

    case initializationFailure

    /// Expected fee in SOL
    case invalidBaseFeeToken

    case missingRelayContext

    case feeIsMoreThanInputAmount
}

public enum InitializingError: Error, Equatable {
    case unauthorized
    case missingArguments
}

public enum WormholeSendInputAlert: Error, Equatable {
    case feeIsMoreThanInputAmount
}
