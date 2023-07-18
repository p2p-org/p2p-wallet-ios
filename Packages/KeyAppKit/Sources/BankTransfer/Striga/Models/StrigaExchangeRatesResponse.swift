import Foundation

public typealias StrigaExchangeRatesResponse = [String: StrigaExchangeRates]

public struct StrigaExchangeRates: Codable {
    let price: String
    let buy: String
    let sell: String
    let timestamp: Int
    let currency: String
}
