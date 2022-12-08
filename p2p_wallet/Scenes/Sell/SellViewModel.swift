import Foundation
import Combine
import Resolver

class SellViewModel: BaseViewModel, ObservableObject {
    
    // MARK: - Dependencies
    
    @Injected private var userWalletManager: UserWalletManager
    // TODO: - Use resolver instead
    private let actionService = SellActionServiceMock()
    private let dataService = SellDataServiceMock()

    // MARK: - Properties

//    @Published var state: SellStateMachine.State
    @Published private(set) var subscene: SellSubScene?
    
    private let externalTransactionId: String = UUID().uuidString

    // MARK: - Actions
    
    func openMoonPayWebView(
        quoteCurrencyCode: String,
        baseCurrencyAmount: Double
    ) throws {
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
            .init(name: "baseCurrencyCode", value: "SOL"),
            .init(name: "refundWalletAddress", value: userWalletManager.wallet?.account.publicKey.base58EncodedString),
            .init(name: "quoteCurrencyCode", value: quoteCurrencyCode),
            .init(name: "baseCurrencyAmount", value: baseCurrencyAmount.toString()),
            .init(name: "externalTransactionId", value: externalTransactionId)
        ]
        
        guard let url = components.url else {
            throw SellError.invalidURL
        }
        
        subscene = .moonpayWebpage(url: url)
    }
}
