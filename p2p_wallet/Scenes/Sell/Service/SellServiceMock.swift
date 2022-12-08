import Combine
import Foundation
import Resolver

class SellDataServiceMock: SellDataService {

    typealias Provider = MoonpaySellDataServiceProvider

    private let statusSubject = PassthroughSubject<SellDataServiceStatus, Never>()
    lazy var status: AnyPublisher<SellDataServiceStatus, Never> = {
        statusSubject.eraseToAnyPublisher()
    }()

    private let lastUpdateDateSubject = PassthroughSubject<Date, Never>()
    lazy var lastUpdateDate: AnyPublisher<Date, Never> = { lastUpdateDateSubject.eraseToAnyPublisher() }()

    func update() async throws {
        
    }

    func incompleteTransactions() async throws -> [Provider.Transaction] {
        []
    }

    func transaction(id: String) async throws -> Provider.Transaction {
        fatalError()
    }

    func isAvailable() async throws -> Bool {
        true
    }
}

class SellActionServiceMock: SellActionService {
    @Injected private var userWalletManager: UserWalletManager
    
    func createSellURL(
        quoteCurrencyCode: String,
        baseCurrencyAmount: Double,
        externalTransactionId: String
    ) throws -> URL {
        #if !RELEASE
        let endpoint = String.secretConfig("MOONPAY_STAGING_SELL_ENDPOINT")!
        let apiKey = String.secretConfig("MOONPAY_STAGING_API_KEY")!
        #else
        let endpoint = String.secretConfig("MOONPAY_PRODUCTION_SELL_ENDPOINT")!
        let apiKey = String.secretConfig("MOONPAY_PRODUCTION_API_KEY")!
        #endif

        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            .init(name: "apiKey", value: apiKey),
            .init(name: "baseCurrencyCode", value: "sol"),
            .init(name: "refundWalletAddress", value: userWalletManager.wallet?.account.publicKey.base58EncodedString),
            .init(name: "quoteCurrencyCode", value: quoteCurrencyCode),
            .init(name: "baseCurrencyAmount", value: baseCurrencyAmount.toString()),
            .init(name: "externalTransactionId", value: externalTransactionId)
        ]

        guard let url = components.url else {
            throw SellError.invalidURL
        }
        return url
    }
    func calculateRates() async throws -> Double { 0 }
    func saveTransaction() async throws {}
    func deleteTransaction() async throws {}
}
