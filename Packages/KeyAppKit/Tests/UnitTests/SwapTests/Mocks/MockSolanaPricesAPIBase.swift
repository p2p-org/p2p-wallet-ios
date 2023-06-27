import Foundation
import SolanaPricesAPIs
import SolanaSwift

class MockSolanaPricesAPIBase: SolanaPricesAPI {
    var pricesNetworkManager: PricesNetworkManager
    
    init(pricesNetworkManager: PricesNetworkManager = MockPricesNetworkManagerBase()) {
        self.pricesNetworkManager = pricesNetworkManager
    }
    
    func getCurrentPrices(coins: [Token], toFiat fiat: String) async throws -> [Token : CurrentPrice?] {
        fatalError()
    }
    
    func getHistoricalPrice(of coinName: String, fiat: String, period: Period) async throws -> [PriceRecord] {
        fatalError()
    }
    
    func getValueInUSD(fiat: String) async throws -> Double? {
        fatalError()
    }
}

class MockPricesNetworkManagerBase: PricesNetworkManager {
    func get(urlString: String) async throws -> Data {
        // Implement mock behavior
        return Data()
    }
}

