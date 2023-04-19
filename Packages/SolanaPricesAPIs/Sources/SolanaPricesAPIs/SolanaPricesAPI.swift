import Foundation
import SolanaSwift

/// Generic protocol to define a cryptocurrency prices provider
public protocol SolanaPricesAPI {
    /// Network manager for prices
    var pricesNetworkManager: PricesNetworkManager {get}
    
    /// Get prices of current set of coins' ticket
    /// - Parameters:
    ///   - coins: The coin tickets to fetch
    ///   - fiat: the fiat, for example: USD
    /// - Returns: The current prices
    func getCurrentPrices(coins: [Token], toFiat fiat: String) async throws -> [Token: CurrentPrice?]
    
    /// Get the historical prices of a given coin
    /// - Parameters:
    ///   - coinName: The coin ticket
    ///   - fiat: the fiat, for example: USD
    ///   - period: period to fetch
    /// - Returns: The records of prices in given period
    func getHistoricalPrice(of coinName: String, fiat: String, period: Period) async throws -> [PriceRecord]
    
    /// Get value of a fiat in USD
    /// - Parameter fiat: fiat (other than USD)
    func getValueInUSD(fiat: String) async throws -> Double?
}

extension SolanaPricesAPI {
    /// Generic get function for retrieving data over network
    func get<T: Decodable>(urlString: String) async throws -> T {
        let data = try await pricesNetworkManager.get(urlString: urlString)
        try Task.checkCancellation()
        return try JSONDecoder().decode(T.self, from: data)
    }
}
