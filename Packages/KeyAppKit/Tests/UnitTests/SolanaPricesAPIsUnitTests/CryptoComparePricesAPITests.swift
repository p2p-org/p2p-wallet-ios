//
//  PricesServiceTests.swift
//  
//
//  Created by Chung Tran on 08/06/2022.
//

import XCTest
import SolanaPricesAPIs
import SolanaSwift

class CryptoComparePricesAPITests: XCTestCase {

    let api = CryptoComparePricesAPI(apikey: nil, pricesNetworkManager: MockNetworkManager())

    func testGetCoinPrices() async throws {
        let btcTokenExtension = try! JSONDecoder().decode(TokenExtensions.self, from: #"{"coingeckoId": "bitcoin"}"#.data(using: .utf8)!)
        let etcTokenExtension = try! JSONDecoder().decode(TokenExtensions.self, from: #"{"coingeckoId": "ethereum"}"#.data(using: .utf8)!)
        let btc = Token(_tags: [], chainId: 0, address: "", symbol: "BTC", name: "Bitcoin", decimals: 18, logoURI: nil, extensions: btcTokenExtension)
        let etc = Token(_tags: [], chainId: 0, address: "", symbol: "ETH", name: "Bitcoin", decimals: 18, logoURI: nil, extensions: etcTokenExtension)
        let prices = try await api.getCurrentPrices(coins: [btc, etc], toFiat: "USD")
        XCTAssertEqual(prices[etc]??.value, 1796.09)
        XCTAssertEqual(prices[btc]??.value, 30231.69)
    }
    
    func testGetHistoricalPrices() async throws {
        let historicalPrices = try await api.getHistoricalPrice(of: "BTC", fiat: "USD", period: .month)
        XCTAssertEqual(historicalPrices.count, 31)
        XCTAssertEqual(historicalPrices[5].close, 31296.11)
        XCTAssertEqual(historicalPrices[18].close, 29013.53)
        XCTAssertEqual(historicalPrices[29].open, 31111.75)
    }
    
    func testGetFiatPrice() async throws {
        let price = try await api.getValueInUSD(fiat: "EUR")
        XCTAssertEqual(price, 0.932)
    }
}

struct MockNetworkManager: PricesNetworkManager {
    func get(urlString: String) async throws -> Data {
        print(urlString)
        if urlString == "https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC,ETH&tsyms=USD"
        {
            return #"{"BTC":{"USD":30231.69},"ETH":{"USD":1796.09}}"#
                .data(using: .utf8)!
        }
        
        if urlString == "https://min-api.cryptocompare.com/data/v2/histoday?limit=30&fsym=BTC&tsym=USD"
        {
            return #"{"Response":"Success","Message":"","HasWarning":false,"Type":100,"RateLimit":{},"Data":{"Aggregated":false,"TimeFrom":1652140800,"TimeTo":1654732800,"Data":[{"time":1652140800,"high":32625.41,"low":29836.19,"open":30076.9,"volumefrom":103840.6,"volumeto":3244062170.09,"close":31013.12,"conversionType":"direct","conversionSymbol":""},{"time":1652227200,"high":32136.04,"low":28087.41,"open":31013.12,"volumefrom":131586.22,"volumeto":3967102738.94,"close":29017.21,"conversionType":"direct","conversionSymbol":""},{"time":1652313600,"high":30085.67,"low":25835.61,"open":29017.21,"volumefrom":160835.32,"volumeto":4501368166.33,"close":28915.72,"conversionType":"direct","conversionSymbol":""},{"time":1652400000,"high":30964.26,"low":28700.17,"open":28915.72,"volumefrom":64448.46,"volumeto":1942170683.15,"close":29244.83,"conversionType":"direct","conversionSymbol":""},{"time":1652486400,"high":30274.18,"low":28588.99,"open":29244.83,"volumefrom":28759.56,"volumeto":845013800.63,"close":30050.31,"conversionType":"direct","conversionSymbol":""},{"time":1652572800,"high":31406.35,"low":29462.91,"open":30050.31,"volumefrom":26775.5,"volumeto":810199953.22,"close":31296.11,"conversionType":"direct","conversionSymbol":""},{"time":1652659200,"high":31296.19,"low":29104.45,"open":31296.11,"volumefrom":41520.45,"volumeto":1242326194.24,"close":29838.5,"conversionType":"direct","conversionSymbol":""},{"time":1652745600,"high":30744.47,"low":29434.76,"open":29838.5,"volumefrom":33082.29,"volumeto":1000070390.57,"close":30415.91,"conversionType":"direct","conversionSymbol":""},{"time":1652832000,"high":30673.66,"low":28610.2,"open":30415.91,"volumefrom":44949.69,"volumeto":1322816665.45,"close":28667.29,"conversionType":"direct","conversionSymbol":""},{"time":1652918400,"high":30505,"low":28653.17,"open":28667.29,"volumefrom":48991.36,"volumeto":1453211639.97,"close":30282.48,"conversionType":"direct","conversionSymbol":""},{"time":1653004800,"high":30725.44,"low":28698.31,"open":30282.48,"volumefrom":57051.25,"volumeto":1692088244.46,"close":29166.15,"conversionType":"direct","conversionSymbol":""},{"time":1653091200,"high":29613.15,"low":28924.28,"open":29166.15,"volumefrom":15780.21,"volumeto":462392582.18,"close":29410.72,"conversionType":"direct","conversionSymbol":""},{"time":1653177600,"high":30454.36,"low":29219.51,"open":29410.72,"volumefrom":21390.13,"volumeto":639923811.62,"close":30264.29,"conversionType":"direct","conversionSymbol":""},{"time":1653264000,"high":30634.84,"low":28861.27,"open":30264.29,"volumefrom":38286.66,"volumeto":1147137210.63,"close":29075.68,"conversionType":"direct","conversionSymbol":""},{"time":1653350400,"high":29800.48,"low":28629.55,"open":29075.68,"volumefrom":28263.22,"volumeto":826118559.89,"close":29630.05,"conversionType":"direct","conversionSymbol":""},{"time":1653436800,"high":30189.17,"low":29321.43,"open":29630.05,"volumefrom":26906.19,"volumeto":800315804.06,"close":29508.27,"conversionType":"direct","conversionSymbol":""},{"time":1653523200,"high":29848.6,"low":28060.72,"open":29508.27,"volumefrom":45080.31,"volumeto":1314694988.34,"close":29188.71,"conversionType":"direct","conversionSymbol":""},{"time":1653609600,"high":29359.16,"low":28251.91,"open":29188.71,"volumefrom":36570.36,"volumeto":1054644721.04,"close":28597.33,"conversionType":"direct","conversionSymbol":""},{"time":1653696000,"high":29234.85,"low":28504.59,"open":28597.33,"volumefrom":12661.88,"volumeto":365397751.75,"close":29013.53,"conversionType":"direct","conversionSymbol":""},{"time":1653782400,"high":29548.72,"low":28820.15,"open":29013.53,"volumefrom":12840.42,"volumeto":374906552.33,"close":29452.23,"conversionType":"direct","conversionSymbol":""},{"time":1653868800,"high":32161.5,"low":29287.63,"open":29452.23,"volumefrom":46295.9,"volumeto":1426112899.49,"close":31716.41,"conversionType":"direct","conversionSymbol":""},{"time":1653955200,"high":32367.02,"low":31203.31,"open":31716.41,"volumefrom":32446.48,"volumeto":1028808882.28,"close":31782.16,"conversionType":"direct","conversionSymbol":""},{"time":1654041600,"high":31956.43,"low":29324.1,"open":31782.16,"volumefrom":43767.18,"volumeto":1343136773.16,"close":29789.58,"conversionType":"direct","conversionSymbol":""},{"time":1654128000,"high":30647.18,"low":29574.16,"open":29789.58,"volumefrom":31049.7,"volumeto":932339972.84,"close":30439.63,"conversionType":"direct","conversionSymbol":""},{"time":1654214400,"high":30676.7,"low":29249.37,"open":30439.63,"volumefrom":24607.85,"volumeto":734000142.92,"close":29680.3,"conversionType":"direct","conversionSymbol":""},{"time":1654300800,"high":29953.65,"low":29466.57,"open":29680.3,"volumefrom":10446.72,"volumeto":310298122.38,"close":29845.48,"conversionType":"direct","conversionSymbol":""},{"time":1654387200,"high":30151.31,"low":29516.97,"open":29845.48,"volumefrom":10423.68,"volumeto":311392830.2,"close":29897.9,"conversionType":"direct","conversionSymbol":""},{"time":1654473600,"high":31740.27,"low":29876.22,"open":29897.9,"volumefrom":34484.33,"volumeto":1076503583.85,"close":31353.78,"conversionType":"direct","conversionSymbol":""},{"time":1654560000,"high":31551.28,"low":29210.15,"open":31353.78,"volumefrom":44308.05,"volumeto":1340573593.65,"close":31111.75,"conversionType":"direct","conversionSymbol":""},{"time":1654646400,"high":31305.48,"low":29839.64,"open":31111.75,"volumefrom":27741.65,"volumeto":844411303.8,"close":30189.27,"conversionType":"direct","conversionSymbol":""},{"time":1654732800,"high":30304.45,"low":30053.44,"open":30189.27,"volumefrom":1700.04,"volumeto":51271782.04,"close":30210.38,"conversionType":"direct","conversionSymbol":""}]}}"#
                .data(using: .utf8)!
        }
        if urlString == "https://min-api.cryptocompare.com/data/price?fsym=USD&tsyms=EUR"
        {
            return #"{"EUR":0.932}"#
                .data(using: .utf8)!
        }
        fatalError()
    }
}
