import Combine
import Foundation
import Combine
import Resolver

@MainActor
class SellViewModel: BaseViewModel, ObservableObject {
    
    // MARK: - Dependencies
    // TODO: Put resolver
    private let dataService: any SellDataService = SellDataServiceMock()
    private let actionService: SellActionService = SellActionServiceMock()

    let coordinator = CoordinatorIO()
private var navigation = PassthroughSubject<SellNavigation?, Never>()
var navigationPublisher: AnyPublisher<SellNavigation?, Never> {
navigation.eraseToAnyPublisher()
}

    // MARK: -

    @Published var isLoading = true

    override init() {
        super.init()

        warmUp()

        let dataStatus = dataService.status
            .receive(on: RunLoop.main)
            .share()

        // 1. Check if pending txs
        dataStatus
            .filter { $0 == .ready }
            .map { _ in false }
            .assign(to: \.isLoading, on: self)
            .store(in: &subscriptions)

        dataStatus
            .filter { $0 == .ready }
            .sink { _ in self.coordinator.showPending.send() }
            .store(in: &subscriptions)

// TODO: - Remove later
#if DEBUG
DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [unowned self] in
try! openProviderWebView(
quoteCurrencyCode: "eur",
baseCurrencyAmount: 10, // 10 SOL
externalTransactionId: UUID().uuidString
)
}
#endif
    }

    private func warmUp() {
        Task {
            try await dataService.update()
        }
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

extension SellViewModel {
    struct CoordinatorIO {
        var showPending = PassthroughSubject<Void, Never>()
    }
}
