import Combine
import Foundation
import Combine
import Resolver
import RxSwift
import KeyAppUI
import SolanaSwift

@MainActor
class SellViewModel: BaseViewModel, ObservableObject {

    // MARK: - Dependencies

    @Injected private var walletRepository: WalletsRepository
    // TODO: Put resolver
    private let dataService: any SellDataService = SellDataServiceMock()
    private let actionService: any SellActionService = SellActionServiceMock()

    // MARK: -

    private let disposeBag = DisposeBag()
    private var navigation = PassthroughSubject<SellNavigation?, Never>()
    var navigationPublisher: AnyPublisher<SellNavigation?, Never> {
        navigation.eraseToAnyPublisher()
    }

    // MARK: -
    // MARK: - Properties

    @Published var baseCurrencyCode: String = "SOL"
    @Published var baseAmount: Double?
    @Published var maxBaseAmount: Double?
    @Published var isEnteringBaseAmount: Bool = false
    @Published var quoteCurrencyCode: String = Fiat.usd.code
    @Published var quoteAmount: Double?
    @Published var isEnteringQuoteAmount: Bool = false
    @Published var exchangeRate: Double = 0
    @Published var fee: Double = 0
    @Published var isLoading = true

    override init() {
        super.init()

        warmUp()

        let dataStatus = dataService.status
            .receive(on: RunLoop.main)
            .share()

        dataStatus
            .filter { $0 == .ready }
            .map { _ in false }
            .handleEvents(receiveOutput: { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.baseAmount = self.dataService.currency.minSellAmount ?? 0
                    self.quoteCurrencyCode = self.dataService.fiat.code
                }
            })
            .assign(to: \.isLoading, on: self)
            .store(in: &subscriptions)

        // Open pendings in case there are pending txs
        dataStatus
            .filter { $0 == .ready }
            .sink { _ in self.navigation.send(.showPending) }
            .store(in: &subscriptions)

        walletRepository.dataDidChange
            .subscribe(onNext: { val in
                self.maxBaseAmount = self.walletRepository.nativeWallet?.amount
            })
            .disposed(by: disposeBag)

        $baseAmount
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .filter { _ in self.isLoading == false }
            .sinkAsync { amount in
                let val = try await self.actionService.sellQuote(
                    baseCurrencyCode: self.baseCurrencyCode.lowercased(),
                    quoteCurrencyCode: self.dataService.fiat.code.uppercased(),
                    baseCurrencyAmount: amount ?? 0,
                    extraFeePercentage: 0
                )
                self.fee = val.feeAmount + val.extraFeeAmount
                self.quoteAmount = val.quoteCurrencyAmount
                self.exchangeRate = val.baseCurrencyPrice
        }
        .store(in: &subscriptions)

        bind()
    }

    private func bind() {
        // enter base amount
        Publishers.CombineLatest($baseAmount, $exchangeRate)
            .filter {[weak self] _ in
                self?.isEnteringBaseAmount == true
            }
            .map { baseAmount, exchangeRate in
                guard let baseAmount else {return nil}
                return baseAmount * exchangeRate
            }
            .assign(to: \.quoteAmount, on: self)
            .store(in: &subscriptions)

        // enter quote amount
        Publishers.CombineLatest($quoteAmount, $exchangeRate)
            .filter {[weak self] _ in
                self?.isEnteringQuoteAmount == true
            }
            .map { quoteAmount, exchangeRate in
                guard let quoteAmount, exchangeRate != 0 else {return nil}
                return quoteAmount / exchangeRate
            }
            .assign(to: \.baseAmount, on: self)
            .store(in: &subscriptions)
    }

    private func warmUp() {
        Task {
            try await dataService.update()
        }
    }

    // MARK: - Actions

    func sell() {
        try! openProviderWebView(
            quoteCurrencyCode: dataService.fiat.code,
            baseCurrencyAmount: baseAmount ?? 0,
            externalTransactionId: walletRepository.nativeWallet?.pubkey ?? UUID().uuidString
        )
    }

    func sellAll() {
        baseAmount = walletRepository.nativeWallet?.amount ?? 0
    }

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
