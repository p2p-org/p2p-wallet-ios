import Foundation

public struct SolanaTokenAmountResponse: Codable, Equatable {
    public let address: String
    public let amount: String

    public var uint64Value: UInt64? {
        UInt64(amount)
    }
}
