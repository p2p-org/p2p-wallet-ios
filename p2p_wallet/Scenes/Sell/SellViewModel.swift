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
    }

    // MARK: - Actions
    
    func openProviderWebView(
        quoteCurrencyCode: String,
        baseCurrencyAmount: Double,
        externalTransactionId: String
    ) throws {
        let url = try actionService.createSellURL(
            quoteCurrencyCode: quoteCurrencyCode,
            baseCurrencyAmount: baseCurrencyAmount,
            externalTransactionId: externalTransactionId
        )
        navigation.send(.webPage(url: url))
    }
}
