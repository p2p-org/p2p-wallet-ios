import Combine
import Foundation
import Resolver

class SellDataServiceMock: SellDataService {
    typealias Provider = MoonpaySellDataServiceProvider
    private var provider = Provider()

    init() {
        statusSubject.send(.initialized)
    }

    private let statusSubject = PassthroughSubject<SellDataServiceStatus, Never>()
    lazy var status: AnyPublisher<SellDataServiceStatus, Never> = {
        statusSubject
            .eraseToAnyPublisher()
    }()

    private let lastUpdateDateSubject = PassthroughSubject<Date, Never>()
    lazy var lastUpdateDate: AnyPublisher<Date, Never> = { lastUpdateDateSubject.eraseToAnyPublisher() }()

    /// List of supported crypto currencies
    private(set) var currencies = [Provider.Currency]()
    private(set) var fiat: Fiat = .usd

    func update() async throws {
        defer {
            statusSubject.send(.ready)
        }
        currencies = try await provider.currencies().filter { $0.code.uppercased() == "SOL" }
        fiat = try await Provider().fiat()
    }

    func incompleteTransactions() async throws -> [Provider.Transaction] {
        let transaction = Provider.Transaction(
            id: "id1",
            createdAt: Date(),
            updatedAt: Date(),
            baseCurrencyAmount: 3,
            quoteCurrencyAmount: 12.3,
            feeAmount: 0.1,
            extraFeeAmount: 0.1,
            status: .pending,
            failureReason: "Something went wrong",
            refundWalletAddress: "address",
            depositHash: "depositHash",
            quoteCurrencyId: "quoteCurrencyId",
            baseCurrencyId: "baseCurrencyId"
        )
        return [transaction]
    }

    func transaction(id: String) async throws -> Provider.Transaction {
        fatalError()
    }

    func isAvailable() async throws -> Bool {
        available(.sellScenarioEnabled)
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
            throw SellActionServiceError.invalidURL
        }
        return url
    }
    func calculateRates() async throws -> Double { 0 }
    func saveTransaction() async throws {}
    func deleteTransaction() async throws {}
}
