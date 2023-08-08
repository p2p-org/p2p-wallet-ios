import Foundation
import KeyAppKitCore

public enum SwapMode: Codable, Hashable {
    case exactIn
    case exactOut
}

public enum FeePayer: Codable, Hashable {
    case service
    case user
}

public struct TransferOptions: Codable, Hashable {
    let swapMode: SwapMode
    let feePayer: FeePayer
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
