import Foundation

// MARK: - SendServiceTransferResponse

public struct SendServiceTransferResponse: Codable, Equatable {
    public let transaction, blockhash: String
    public let expiresAt: UInt64
    public let signature: String
    public let recipientGetsAmount, totalAmount: SendServiceTransferAmount
    public let networkFee: SendServiceTransferFee
    public let tokenAccountRent, token2022_TransferFee: SendServiceTransferFee?

    enum CodingKeys: String, CodingKey {
        case transaction, blockhash
        case expiresAt = "expires_at"
        case signature
        case recipientGetsAmount = "recipient_gets_amount"
        case totalAmount = "total_amount"
        case networkFee = "network_fee"
        case tokenAccountRent = "token_account_rent"
        case token2022_TransferFee = "token_2022_transfer_fee"
    }
}

// MARK: - NetworkFee

public struct SendServiceTransferFee: Codable, Equatable {
    public let source: String
    public let amount: SendServiceTransferAmount
}

// MARK: - Amount

public struct SendServiceTransferAmount: Codable, Equatable {
    public let amount, usdAmount, address, symbol: String
    public let name: String
    public let decimals: Int
    public let logoURL: String?
    public let coingeckoID: String?
    public let price: SendServiceTransferPrice

    enum CodingKeys: String, CodingKey {
        case amount
        case usdAmount = "usd_amount"
        case address, symbol, name, decimals
        case logoURL = "logo_url"
        case coingeckoID = "coingecko_id"
        case price
    }
}

// MARK: - Price

public struct SendServiceTransferPrice: Codable, Equatable {
    let usd: String?
}
