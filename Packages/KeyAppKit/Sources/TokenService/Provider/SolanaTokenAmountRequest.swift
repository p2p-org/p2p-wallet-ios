import Foundation

public struct SolanaTokenAmountRequest: Codable, Equatable {
    public let vs_token: String?
    public let amount: String
    public let mints: [String]
}
