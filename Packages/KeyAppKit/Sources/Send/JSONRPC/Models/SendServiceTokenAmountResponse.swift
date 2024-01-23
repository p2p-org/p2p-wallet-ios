import Foundation

public struct SendServiceTokenAmountResponse: Codable, Equatable {
    public let address: String
    public let amount: String

    var uint64Value: UInt64? {
        UInt64(amount)
    }
}
