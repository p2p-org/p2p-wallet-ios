import Foundation
import KeyAppKitCore

public enum SwapMode: String, Codable, Hashable {
    case exactIn = "ExactIn"
    case exactOut = "ExactOut"
}

public enum FeePayer: String, Codable, Hashable {
    case service = "Service"
    case user = "User"
}

public struct TransferOptions: Codable, Hashable {
    let swapMode: SwapMode
    let feePayer: FeePayer

    public init(swapMode: SwapMode, feePayer: FeePayer) {
        self.swapMode = swapMode
        self.feePayer = feePayer
    }
}

public struct SendResponse: Codable, Hashable {
    let transactionDetails: TransactionDetails
    let transferAmounts: TransferAmounts
    let fees: TransferFees
}

public struct TransactionDetails: Codable, Hashable {
    let transaction: String
    let blockhash: String
    let expiresAt: UInt64
    let signature: String
}

public struct TransferAmounts: Codable, Hashable {
    let recipient_gets_amount: TokenAmount
    let total_amount: TokenAmount
}

public struct TransferFees: Codable, Hashable {
    let networkFee: Fee
    let tokenAccountRent: Fee?
}

public enum FeeSource: String, Codable, Hashable {
    case serviceCoverage = "service_coverage"
    case userCompensated = "user_compensated"
    case user
}

public struct Fee: Codable, Hashable {
    let source: FeeSource
    let amount: String
}

public struct TokenAmount: Codable, Hashable {
    let amount: UInt64
    let usdAmount: Decimal
    let mint: String
    let meta: SolanaToken
}
