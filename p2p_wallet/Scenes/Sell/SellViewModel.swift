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
    private let dataService: any SellDataService = MoonpaySellDataService()
    private let actionService: any SellActionService = SellActionServiceMock()

    // MARK: -

    private let disposeBag = DisposeBag()
    private var navigation = PassthroughSubject<SellNavigation?, Never>()
    var navigationPublisher: AnyPublisher<SellNavigation?, Never> {
        navigation.eraseToAnyPublisher()
    }

    // MARK: -

    private var minBaseAmount: Double?
    /// Maximum value to sell from sell provider
    private var maxBaseProviderAmount: Double?
    private let baseAmountTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    // MARK: - Properties

    @Published var baseCurrencyCode: String = "SOL"
    @Published var baseAmount: Double?
    /// Maximum amount user can sell (balance)
    @Published var maxBaseAmount: Double?
    @Published var isEnteringBaseAmount: Bool = true
    @Published var quoteCurrencyCode: String = Fiat.usd.code
    @Published var quoteAmount: Double?
    @Published var isEnteringQuoteAmount: Bool = false
    @Published var exchangeRate: Double = 0
    @Published var fee: Double = 0
    @Published var isLoading = true
    @Published var hasPending = false
    @Published var errorText: String?

    override init() {
        super.init()

        warmUp()

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
                    self.maxBaseProviderAmount = self.dataService.currency.maxSellAmount ?? 0
                    self.baseCurrencyCode = "SOL"
                }
            })
            .assign(to: \.isLoading, on: self)
            .store(in: &subscriptions)

        // Open pendings in case there are pending txs
        dataStatus
//            .filter { $0 == .ready }
            .sinkAsync(receiveValue: { _ in
                guard let address = self.walletRepository.nativeWallet?.pubkey else { return }
                let txs = try await self.dataService.incompleteTransactions(transactionId: address)
                if !txs.isEmpty {
                    self.navigation.send(.showPending(transactions: txs))
                }
            })
            .store(in: &subscriptions)

        maxBaseAmount = walletRepository.nativeWallet?.amount
        walletRepository.dataDidChange
            .subscribe(onNext: { val in
                self.maxBaseAmount = self.walletRepository.nativeWallet?.amount
            })
            .disposed(by: disposeBag)

        Publishers.Merge(
            $baseAmount,
            baseAmountTimer.withLatestFrom($baseAmount)
        )
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .withLatestFrom(Publishers.CombineLatest3(
                $baseCurrencyCode, $quoteCurrencyCode, $baseAmount.compactMap { $0 }
            ))
            .filter { _ in !self.isLoading && self.isEnteringBaseAmount }
            .handleEvents(receiveOutput: { [unowned self] amount in
                self.errorText = nil
                self.checkError(amount: amount.2)
            })
            .map { [unowned self] base, quote, amount -> AnyPublisher<SellActionServiceQuote?, Never> in
                self.calculateFee(
                    amount: amount,
                    baseCurrencyCode: base,
                    quoteCurrencyCode: quote
                )
                    .map(Optional.init)
                    .replaceError(with: nil)
                    .eraseToAnyPublisher()
            }
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            // Getting only last request
            .switchToLatest()
            .sink(receiveValue: { [unowned self] val in
                guard let val else {
                    if self.isEnteringBaseAmount {
                        self.quoteAmount = 0
                    } else {
                        self.baseAmount = 0
                    }
                    return
                }
                self.fee = val.feeAmount + val.extraFeeAmount
                self.quoteAmount = val.quoteCurrencyAmount
                self.exchangeRate = val.baseCurrencyPrice
            })
            .store(in: &subscriptions)
    }

    private func warmUp() {
        Task {
            try await dataService.update(id: "DRMDSujkGuy2EcY9c8nEwVJzo8LbhohWG9okkaivAomx")
        }
    }

    private func checkError(amount: Double) {
        if amount < self.minBaseAmount {
            self.errorText = L10n.theMinimumAmountIs(self.minBaseAmount.toString(), self.baseCurrencyCode)
        } else if amount > (self.maxBaseAmount ?? 0) {
            self.errorText = L10n.notEnought(self.baseCurrencyCode)
        } else if amount > self.maxBaseProviderAmount {
            self.errorText = L10n.theMaximumAmountIs(self.maxBaseProviderAmount.toString(), self.baseCurrencyCode)
        }
    }

    private func calculateFee(
        amount: Double,
        baseCurrencyCode: String,
        quoteCurrencyCode: String
    ) -> AnyPublisher<SellActionServiceQuote, Error> {
        Deferred {
            Future { promise in
                Task { [unowned self] in
                    do {
                        let result = try await self.actionService.sellQuote(
                            baseCurrencyCode: baseCurrencyCode.lowercased(),
                            quoteCurrencyCode: quoteCurrencyCode.lowercased(),
                            baseCurrencyAmount: amount.rounded(decimals: 2),
                            extraFeePercentage: 0
                        )
                        promise(.success(result))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
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

extension SellViewModel {
    enum _Error: Error {
        case invalidAmount
    }
}
