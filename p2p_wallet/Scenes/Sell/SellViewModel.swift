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
    private var subscene = PassthroughSubject<SellSubScene?, Never>()
    var subscenePublisher: AnyPublisher<SellSubScene?, Never> {
        subscene.eraseToAnyPublisher()
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
        subscene.send(.moonpayWebpage(url: url))
    }
}
