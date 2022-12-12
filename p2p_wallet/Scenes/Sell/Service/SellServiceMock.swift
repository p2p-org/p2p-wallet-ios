import Combine
import Foundation
import Resolver
import SwiftyUserDefaults

class MockSellDataService: SellDataService {
    typealias Provider = MoonpaySellDataServiceProvider
    private var provider = Provider()

    init() {
        statusSubject.send(.initialized)
    }

    @SwiftyUserDefault(keyPath: \.isSellAvailable, options: .cached)
    private var cachedIsAvailable: Bool?

    private let statusSubject = PassthroughSubject<SellDataServiceStatus, Never>()
    lazy var status: AnyPublisher<SellDataServiceStatus, Never> = {
        statusSubject.eraseToAnyPublisher()
    }()

    private let lastUpdateDateSubject = PassthroughSubject<Date, Never>()
    lazy var lastUpdateDate: AnyPublisher<Date, Never> = { lastUpdateDateSubject.eraseToAnyPublisher() }()

    /// List of supported crypto currencies
    private(set) var currency: ProviderCurrency!
    private(set) var fiat: Fiat!

    func update() async throws {
        guard
            let currency = try await provider.currencies().filter({ $0.code.uppercased() == "SOL" }).first else {
            statusSubject.send(.error)
            return
        }
        self.currency = currency
        do {
            self.fiat = try await provider.fiat()
        } catch {
            self.fiat = .usd
//            fatalError("Unsupported fiat")
        }
        statusSubject.send(.ready)
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

    func transaction(id: String) async -> Provider.Transaction {
        fatalError()
    }

    func isAvailable() async -> Bool {
        guard cachedIsAvailable == nil else {
            defer {
                Task {
                    do {
                        cachedIsAvailable = try await provider.isAvailable()
                    } catch {}
                }
            }
            return cachedIsAvailable ?? false
        }
        do {
            cachedIsAvailable = try await provider.isAvailable()
        } catch {
            return false
        }
        return (cachedIsAvailable ?? false)
    }
}

class SellActionServiceMock: SellActionService {
    typealias Provider = MoonpaySellActionServiceProvider
    private var provider = Provider()

    @Injected private var userWalletManager: UserWalletManager

    func sellQuote(
        baseCurrencyCode: String,
        quoteCurrencyCode: String,
        baseCurrencyAmount: Double,
        extraFeePercentage: Double
    ) async throws -> Provider.Quote {
        try await provider.sellQuote(
            baseCurrencyCode: baseCurrencyCode,
            quoteCurrencyCode: quoteCurrencyCode,
            baseCurrencyAmount: baseCurrencyAmount
        )
    }

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

    func saveTransaction() async throws {}
    func deleteTransaction() async throws {}
}
