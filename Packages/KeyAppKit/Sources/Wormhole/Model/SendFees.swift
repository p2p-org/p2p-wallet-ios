import Foundation
import KeyAppKitCore

public struct SendFees: Codable, Hashable, Equatable {
    public let recipientGetsAmount: TokenAmount?

    /// Receive amount for user B. Nil when fees are greater than sending amount.
    public let totalAmount: TokenAmount?

    /// Process fee in Ethereum network.
    public let arbiter: TokenAmount?

    /// Network fee in Solana network (SOL).
    public let networkFee: TokenAmount?

    /// Network fee in Solana network (in same result amount token).
    public let networkFeeInToken: TokenAmount?

    /// Account creation fee in Solana network (SOL).
    public let messageAccountRent: TokenAmount?

    /// Account creation fee in Solana network (in same result amount token).
    public let messageAccountRentInToken: TokenAmount?

    /// Bridge fee in Solana network (SOL).
    public let bridgeFee: TokenAmount?

    /// Bridge fee in Solana network (in same result amount token).
    public let bridgeFeeInToken: TokenAmount?

    enum CodingKeys: String, CodingKey {
        case recipientGetsAmount = "recipient_gets_amount"
        case totalAmount = "total_amount"
        case arbiter = "arbiter_fee"
        case networkFee = "network_fee"
        case networkFeeInToken = "network_fee_in_token"
        case messageAccountRent = "message_account_rent"
        case messageAccountRentInToken = "message_account_rent_in_token"
        case bridgeFee = "bridge_fee"
        case bridgeFeeInToken = "bridge_fee_in_token"
    }
}
