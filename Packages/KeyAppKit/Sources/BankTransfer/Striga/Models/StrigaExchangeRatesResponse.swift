import Foundation

public typealias StrigaExchangeRatesResponse = [String: StrigaExchangeRates]

public struct StrigaExchangeRates: Codable {
    public let price: String
    public let buy: String
    public let sell: String
    public let timestamp: Int
    public let currency: String
}
