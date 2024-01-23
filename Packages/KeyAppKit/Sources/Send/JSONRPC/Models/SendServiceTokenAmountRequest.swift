import Foundation

public struct SendServiceTokenAmountRequest: Codable, Equatable {
    public let vs_token: String?
    public let amount: String
    public let mints: [String]
}
