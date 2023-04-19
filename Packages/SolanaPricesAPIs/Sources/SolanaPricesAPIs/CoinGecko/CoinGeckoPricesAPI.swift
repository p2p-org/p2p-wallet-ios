import Cache
import Foundation
import SolanaSwift

/// Prices provider from cryptocompare.com
public class CoinGeckoPricesAPI: SolanaPricesAPI {
    enum CacheKeys: String {
        case coinlist
    }
    
    private let cache = Cache<String, [Coin]>()
    
    private let endpoint = "https://api.coingecko.com/api/v3"
    
    public var pricesNetworkManager: PricesNetworkManager
    
    public init(pricesNetworkManager: PricesNetworkManager = DefaultPricesNetworkManager()) {
        self.pricesNetworkManager = pricesNetworkManager
    }
    
    public func getCurrentPrices(coins: [Token], toFiat fiat: String) async throws -> [Token: CurrentPrice?] {
        let param = coins.compactMap { $0.extensions?.coingeckoId }.unique.joined(separator: ",")
        let pricesResult: [CoinMarketData] = try await get(urlString: endpoint + "/coins/markets/?vs_currency=\(fiat)&ids=\(param)")
        return pricesResult.reduce(into: [Token: CurrentPrice?]()) { partialResult, data in
            guard let token = coins.first(where: { $0.extensions?.coingeckoId == data.id }) else { return }
            partialResult[token] = .init(
                value: data.current_price,
                change24h: .init(value: data.price_change_24h, percentage: data.price_change_percentage_24h))
        }
    }
    
    /// Simple price response data struct. [Contract: [Fiat: Price]]
    public typealias SimplePriceResponse = [String: [String: Decimal]]
    
    /// Return simple price by id.
    public func getSimplePrice(ids: [String], fiat: [String]) async throws -> SimplePriceResponse {
        let idsStr = ids.joined(separator: ",")
        let fiatStr = fiat.joined(separator: ",")
        return try await get(urlString: endpoint + "/simple/price?ids=\(idsStr)&vs_currencies=\(fiatStr)")
    }
    
    /// Return simple price by platform and contracts.
    public func getSimpleTokenPrice(platform: String, contractAddresses: [String], fiat: [String]) async throws -> SimplePriceResponse {
        let fiatStr = fiat.joined(separator: ",")
        let contractAddressesStr = contractAddresses.joined(separator: ",")
        return try await get(urlString: endpoint + "/simple/token_price/\(platform)?contract_addresses=\(contractAddressesStr)&vs_currencies=\(fiatStr)")
    }
    
    public func getHistoricalPrice(of coinName: String, fiat: String, period: Period) async throws -> [PriceRecord] {
        var geckoCoinsResult: [Coin] = await cache.value(forKey: CacheKeys.coinlist.rawValue) ?? []
        if geckoCoinsResult.isEmpty {
            geckoCoinsResult = try await get(urlString: endpoint + "/coins/list")
            await cache.insert(geckoCoinsResult, forKey: CacheKeys.coinlist.rawValue)
        }
        let geckoCoins = geckoCoinsResult.filter { geckoCoin in
            geckoCoin.symbol.lowercased() == coinName.lowercased()
        }.map { $0.id }
        assert(geckoCoins.count == 1)
        guard let coinId = geckoCoins.first else { return [] }
        
        let toFiat = fiat.lowercased()
        var daily = "&period=daily"
        var days = 30
        switch period {
        case .last1h, .last4h, .day:
            daily = ""
            days = 1
        case .week:
            days = 6
        case .month:
            days = 30
        }
        
        var priceRecordData = [Date: [Double]]()
        
        let result: HistoryResponse? = try await get(urlString: endpoint + "/coins/\(coinId)/market_chart?vs_currency=\(toFiat)&days=\(days)\(daily)")
        
        result?.prices.forEach { data in
            assert(data.count == 2)
            
            guard let timestamp = data.first, let price = data.last else { return }
            
            switch (timestamp, price) {
            case (.timestamp(let tms), .price(let prc)):
                let date = Date(timeIntervalSince1970: TimeInterval(tms / 1000))
                var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                var key = Calendar.current.date(from: components) ?? Date()
                switch period {
                case .last1h:
                    components.hour = Calendar.current.component(.hour, from: date)
                    key = Calendar.current.date(from: components) ?? Date()
                    guard date.timeIntervalSinceNow > -60*60 else { return }
                case .last4h:
                    components.hour = Calendar.current.component(.hour, from: date)
                    key = Calendar.current.date(from: components) ?? Date()
                    guard date.timeIntervalSinceNow > -4*60*60 else { return }
                case .day:
                    guard date.timeIntervalSinceNow > -60*60*24 else { return }
                case .week:
                    guard date.timeIntervalSinceNow > -60*60*24*7 else { return }
                case .month:
                    guard date.timeIntervalSinceNow > -60*60*24*31 else { return }
                }
                if priceRecordData[key] == nil {
                    priceRecordData[key] = [prc]
                } else {
                    priceRecordData[key]?.append(prc)
                }
            default:
                assert(true)
            }
        }
        
        return priceRecordData.compactMap { val in
            guard
                let open = val.value.first,
                let close = val.value.last,
                let high = val.value.max(),
                let low = val.value.min() else { return nil }
            return PriceRecord(close: close, open: open, low: low, high: high, startTime: val.key)
        }
    }
    
    public func getValueInUSD(fiat: String) async throws -> Double? {
        let toFiat = fiat.lowercased()
        let result: [String: [String: Double]]? = try await get(urlString: endpoint + "/simple/price?ids=usd&vs_currencies=\(toFiat)")
        return result?["usd"]?[toFiat]
    }
    
    // MARK: -

    struct Coin: Codable {
        var id: String
        var symbol: String
        var name: String
    }
    
    struct CoinMarketData: Codable {
        var id: String
        var symbol: String
        var name: String
        var current_price: Double
        var price_change_24h: Double?
        var price_change_percentage_24h: Double?
    }
    
    enum HistoryResponsePriceData: Decodable {
        case timestamp(timestamp: Int)
        case price(price: Double)
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let value = try? container.decode(Int.self) {
                self = .timestamp(timestamp: value)
                return
            } else if let value = try? container.decode(Double.self) {
                self = .price(price: value)
                return
            }
            fatalError()
        }
        
        enum CodingKeys: CodingKey, CaseIterable {
            case timestamp
            case price
        }
    }
    
    struct HistoryResponse: Decodable {
        var prices: [[HistoryResponsePriceData]]
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            prices = try container.decode([[HistoryResponsePriceData]].self, forKey: .prices)
        }
        
        enum CodingKeys: String, CodingKey {
            case prices
        }
    }
}
