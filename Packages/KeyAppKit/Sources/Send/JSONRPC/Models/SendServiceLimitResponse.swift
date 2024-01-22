import Foundation

// MARK: - SendServiceLimitResponse

public struct SendServiceLimitResponse: Codable, Equatable {
    public let networkFee, tokenAccountRent: SendServiceLimitRemaining

    enum CodingKeys: String, CodingKey {
        case networkFee = "network_fee"
        case tokenAccountRent = "token_account_rent"
    }
}

// MARK: - NetworkFee

public struct SendServiceLimitRemaining: Codable, Equatable {
    public let remainingAmount, remainingTransactions: UInt64

    enum CodingKeys: String, CodingKey {
        case remainingAmount = "remaining_amount"
        case remainingTransactions = "remaining_transactions"
    }
}
