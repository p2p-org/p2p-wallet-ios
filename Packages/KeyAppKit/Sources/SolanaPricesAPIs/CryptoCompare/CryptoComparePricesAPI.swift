import Foundation
import SolanaSwift

/// Prices provider from cryptocompare.com
public class CryptoComparePricesAPI: SolanaPricesAPI {
    // MARK: - Properties
    
    /// Network manager
    public var pricesNetworkManager: PricesNetworkManager
    
    /// Endpoint of the provider
    private let endpoint = "https://min-api.cryptocompare.com/data"
    
    /// Custom api key
    private let apikey: String?
    
    // MARK: - Initializer
    public init(apikey: String?, pricesNetworkManager: PricesNetworkManager = DefaultPricesNetworkManager()) {
        self.apikey = apikey
        self.pricesNetworkManager = pricesNetworkManager
    }
    
    // MARK: - Methods
    public func getCurrentPrices(coins: [Token], toFiat fiat: String) async throws -> [Token: CurrentPrice?] {
        let chunk = coins.chunked(into: 30)
        return await withTaskGroup(of: [String: CurrentPrice?].self) { group in
            for part in chunk {
                group.addTask { [weak self] in
                    (try? await self?.getCurrentPrices(partialCoins: part.map {$0.symbol}, toFiat: fiat)) ?? [:]
                }
            }
            var dictArray = [[String: CurrentPrice?]]()
            for await result in group {
                dictArray.append(result)
            }
            let tupleArray: [(String, CurrentPrice?)] = dictArray.flatMap { $0 }
            let dictonary = Dictionary(tupleArray, uniquingKeysWith: { first, _ in first })
            
            return Dictionary(
                coins.map({ (token) -> (Token, CurrentPrice?) in
                    guard let price = dictonary[token.symbol] else { return (token, nil) }
                    return (token, price)
                }),
                uniquingKeysWith: { first, _ in first }
            )
        }
        
    }
    
    public func getHistoricalPrice(of coinName: String, fiat: String, period: Period) async throws -> [PriceRecord] {
        var path = "/v2"
        switch period {
        case .last1h:
            path += "/histominute?limit=60"
        case .last4h:
            path += "/histominute?limit=240" // 60*4
        case .day:
            path += "/histohour?limit=24"
        case .week:
            path += "/histoday?limit=7"
        case .month:
            path += "/histoday?limit=30"
        }
        path += "&"
        if let apikey = apikey {
            path += "api_key=\(apikey)&"
        }
        path += "fsym=\(coinName)&tsym=\(fiat)"
        
        let response: Response = try await get(urlString: endpoint + path)
            
        return response.Data.Data
            .map {
                PriceRecord(
                    close: $0.close,
                    open: $0.open,
                    low: $0.low,
                    high: $0.high,
                    startTime: Date(timeIntervalSince1970: TimeInterval($0.time))
                )
            }
            
    }
    
    public func getValueInUSD(fiat: String) async throws -> Double? {
        let response: [String: Double] = try await get(urlString: endpoint + "/price?fsym=USD&tsyms=\(fiat)")
        return response[fiat]
    }
    
    // MARK: - Helpers
    private func getCurrentPrices(partialCoins coins: [String], toFiat fiat: String) async throws -> [String: CurrentPrice?] {
        var path = "/pricemulti?"
        let coinListQuery = coins
            .joined(separator: ",")
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        //
        if let apikey = apikey {
            path += "api_key=\(apikey)&"
        }
        
        path += "fsyms=\(coinListQuery)&tsyms=\(fiat)"
        
        let dict: [String: [String: Double]] = try await get(urlString: endpoint + path)
        var result = [String: CurrentPrice?]()
        for key in dict.keys {
            var price: CurrentPrice?
            if let value = dict[key]?[fiat] {
                price = CurrentPrice(value: value)
            }
            result[key] = price
        }
        return result
    }
}

extension CryptoComparePricesAPI {
    struct Response: Decodable {
//        "Response": "Success",
//        "Message": "",
//        "HasWarning": false,
//        "Type": 100,
//        "RateLimit": {},
        let Data: ResponseData
    }

    struct ResponseData: Decodable {
//        "Aggregated": false,
//        "TimeFrom": 1611532800,
//        "TimeTo": 1612396800,
        let Data: [ResponseDataData]
    }

    struct ResponseDataData: Decodable {
//        "high": 34881.18,
//        "low": 31937.09,
//        "open": 32283.66,
//        "volumefrom": 59529.49,
//        "volumeto": 1989618039.07,
//        "conversionType": "direct",
//        "conversionSymbol": ""
        let time: UInt64
        let close: Double
        let high: Double
        let low: Double
        let open: Double
    }
}

extension Array {
    fileprivate func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
