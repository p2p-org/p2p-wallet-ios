import Foundation

// MARK: - SendServiceLimitResponse

public struct SendServiceLimitResponse: Codable, Equatable {
    public let networkFee, tokenAccountRent: SendServiceLimitRemaining

    public init(
        networkFee: SendServiceLimitRemaining,
        tokenAccountRent: SendServiceLimitRemaining
    ) {
        self.networkFee = networkFee
        self.tokenAccountRent = tokenAccountRent
    }

    enum CodingKeys: String, CodingKey {
        case networkFee = "network_fee"
        case tokenAccountRent = "token_account_rent"
    }
}

// MARK: - NetworkFee

public struct SendServiceLimitRemaining: Codable, Equatable {
    public let remainingAmount, remainingTransactions: UInt64

    public init(
        remainingAmount: UInt64,
        remainingTransactions: UInt64
    ) {
        self.remainingAmount = remainingAmount
        self.remainingTransactions = remainingTransactions
    }

    enum CodingKeys: String, CodingKey {
        case remainingAmount = "remaining_amount"
        case remainingTransactions = "remaining_transactions"
    }
}
