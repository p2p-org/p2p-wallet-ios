import Foundation
import Combine
import Resolver

class SellViewModel: BaseViewModel, ObservableObject {
    
    // MARK: - Dependencies
    
    // TODO: - Use resolver instead
    private let actionService = SellActionServiceMock()
    private let dataService = SellDataServiceMock()

    // MARK: - Properties

//    @Published var state: SellStateMachine.State
    private var navigation = PassthroughSubject<SellNavigation?, Never>()
    var navigationPublisher: AnyPublisher<SellNavigation?, Never> {
        navigation.eraseToAnyPublisher()
    }
    
    // MARK: - Initializer
    
    override init() {
        super.init()
        // TODO: - Remove later
        #if DEBUG
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [unowned self] in
            try! openMoonPayWebView(
                quoteCurrencyCode: "eur",
                baseCurrencyAmount: 10, // 10 SOL
                externalTransactionId: UUID().uuidString
            )
        }
        #endif
    }

    // MARK: - Actions
    
    func openMoonPayWebView(
        quoteCurrencyCode: String,
        baseCurrencyAmount: Double,
        externalTransactionId: String
    ) throws {
        let url = try actionService.createSellURL(
            quoteCurrencyCode: quoteCurrencyCode,
            baseCurrencyAmount: baseCurrencyAmount,
            externalTransactionId: externalTransactionId
        )
        navigation.send(.moonpayWebpage(url: url))
    }
}
