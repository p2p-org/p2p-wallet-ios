import Foundation

public struct FeeEstimateResponse: Codable {
    public let totalFee: String
    public let networkFee: String
    public let ourFee: String
    public let theirFee: String
    public let feeCurrency: String
    public let gasLimit: String
    public let gasPrice: String
}
