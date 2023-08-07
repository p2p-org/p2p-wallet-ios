import Foundation

public struct SendTransaction: Hashable, Codable {
    public let transaction: String
    public let message: String
}
