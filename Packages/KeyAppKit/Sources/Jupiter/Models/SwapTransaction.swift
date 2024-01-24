import Foundation

// TODO(jupiter): rename to SwapResponse
public struct SwapTransaction: Codable, Equatable {
    public let stringValue: String
    // public let lastValidBlockHeight: Int
    // public let prioritizationFeeLamports: Int?
    public let receivedAt: Date
}
