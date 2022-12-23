import AnalyticsManager
import Combine
import Foundation
import Combine
import Resolver
import RxSwift
import KeyAppUI
import SolanaSwift
import Sell

enum SellViewModelInputError: Error, Equatable {
    case amountIsTooSmall(minBaseAmount: Double?, baseCurrencyCode: String)
    case insufficientFunds(baseCurrencyCode: String)
    case exceedsProviderLimit(maxBaseProviderAmount: Double?, baseCurrencyCode: String)
    
    var recomendation: String {
        switch self {
        case .amountIsTooSmall(let minBaseAmount, let baseCurrencyCode):
            return L10n.theMinimumAmountIs(minBaseAmount.toString(), baseCurrencyCode)
        case .insufficientFunds(let baseCurrencyCode):
            return L10n.notEnought(baseCurrencyCode)
        case .exceedsProviderLimit(let maxBaseProviderAmount, let baseCurrencyCode):
            return L10n.theMaximumAmountIs(maxBaseProviderAmount.toString(), baseCurrencyCode)
        }
    }
}

@MainActor
class SellViewModel: BaseViewModel, ObservableObject {

    // MARK: - Dependencies

    @Injected private var walletRepository: WalletsRepository
    @Injected private var dataService: any SellDataService
    @Injected private var actionService: any SellActionService
    @Injected private var analyticsManager: AnalyticsManager

    // MARK: -

    private let navigation: PassthroughSubject<SellNavigation?, Never>

    // MARK: -

    @Published var minBaseAmount: Double?
    /// Maximum value to sell from sell provider
    private var maxBaseProviderAmount: Double?
    private let baseAmountTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    // MARK: - Properties
    @Published var isMoreBaseCurrencyNeeded: Bool = false

    @Published var baseCurrencyCode: String = "SOL"
    @Published var baseAmount: Double?
    @Published var maxBaseAmount: Double?
    @Published var isEnteringBaseAmount: Bool = true
    
    @Published var quoteCurrencyCode: String = Fiat.usd.code
    @Published var quoteAmount: Double?
    @Published var isEnteringQuoteAmount: Bool = false
    
    @Published var exchangeRate: Double = 0
    @Published var fee: Double = 0
    @Published var status: SellDataServiceStatus = .initialized {
        didSet {
            switch status {
            case .error(let error):
                analyticsManager.log(event: AmplitudeEvent.sellClickedSorryMinAmount)
            default:
                break
            }
        }
    }
    @Published var inputError: SellViewModelInputError?

    init(navigation: PassthroughSubject<SellNavigation?, Never>) {
        self.navigation = navigation
        super.init()

        warmUp()

        bind()
    }

    private func bind() {
        // enter base amount
        Publishers.CombineLatest($baseAmount, $exchangeRate)
            .filter { [weak self] _ in
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
            .filter { [weak self] _ in
                self?.isEnteringQuoteAmount == true
            }
            .map { quoteAmount, exchangeRate in
                guard let quoteAmount, exchangeRate != 0 else { return nil }
                return quoteAmount / exchangeRate
            }
            .assign(to: \.baseAmount, on: self)
            .store(in: &subscriptions)
        
        // bind status publisher to status property
        dataService.statusPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.status, on: self)
            .store(in: &subscriptions)

        // bind dataService.data to viewModel's data
        let dataPublisher = dataService.statusPublisher
            .compactMap({ [weak self] status in
                switch status {
                case .ready:
                    return (self?.dataService.currency, self?.dataService.fiat)
                default:
                    return nil
                }
            })
            .receive(on: RunLoop.main)
            .share()
        
        dataPublisher
            .sink(receiveValue: { [weak self] currency, fiat in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.baseAmount = currency?.minSellAmount ?? 0
                    self.quoteCurrencyCode = fiat?.code ?? "USD"
                    self.maxBaseProviderAmount = currency?.maxSellAmount ?? 0
                    self.minBaseAmount = currency?.minSellAmount ?? 0
                    self.baseCurrencyCode = "SOL"
                    self.checkIfMoreBaseCurrencyNeeded()
                }
            })
            .store(in: &subscriptions)

        // Open pendings in case there are pending txs
        dataPublisher
            .withLatestFrom(dataService.transactionsPublisher)
            .map { $0.filter { $0.status == .waitingForDeposit }}
            .removeDuplicates()
            .sink(receiveValue: { [weak self] transactions in
                guard let self = self, let fiat = self.dataService.fiat else { return }
                guard !self.isMoreBaseCurrencyNeeded else { return }
                self.navigation.send(.showPending(transactions: transactions, fiat: fiat))
            })
            .store(in: &subscriptions)

        // observe native wallet's changes
        checkIfMoreBaseCurrencyNeeded()
        walletRepository.dataDidChange
            .publisher
            .replaceError(with: ())
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] val in
                self?.checkIfMoreBaseCurrencyNeeded()
            })
            .store(in: &subscriptions)

        Publishers.Merge(
            $baseAmount,
            baseAmountTimer.withLatestFrom($baseAmount)
        )
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .withLatestFrom(Publishers.CombineLatest3(
                $baseCurrencyCode, $quoteCurrencyCode, $baseAmount.compactMap { $0 }
            ))
            .filter { [unowned self] _ in self.status.isReady && self.isEnteringBaseAmount }
            .handleEvents(receiveOutput: { [unowned self] amount in
                self.inputError = nil
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

    func warmUp() {
        Task { [unowned self] in
            await dataService.update()
        }
    }
    
    private func checkIfMoreBaseCurrencyNeeded() {
        maxBaseAmount = walletRepository.nativeWallet?.amount
        if maxBaseAmount < minBaseAmount {
            isMoreBaseCurrencyNeeded = true
        }
    }

    private func checkError(amount: Double) {
        if amount < minBaseAmount {
            inputError = .amountIsTooSmall(minBaseAmount: minBaseAmount, baseCurrencyCode: baseCurrencyCode)
            analyticsManager.log(event: AmplitudeEvent.sellClickedServerError)
        } else if amount > (maxBaseAmount ?? 0) {
            inputError = .insufficientFunds(baseCurrencyCode: baseCurrencyCode)
            analyticsManager.log(event: AmplitudeEvent.sellClickedServerError)
        } else if amount > maxBaseProviderAmount {
            inputError = .exceedsProviderLimit(
                maxBaseProviderAmount: maxBaseProviderAmount,
                baseCurrencyCode: baseCurrencyCode
            )
            analyticsManager.log(event: AmplitudeEvent.sellClickedServerError)
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
        analyticsManager.log(event: AmplitudeEvent.sellAmountNext)
        guard let fiat = dataService.fiat else { return }

        try? openProviderWebView(
            quoteCurrencyCode: fiat.code,
            baseCurrencyAmount: baseAmount ?? 0,
            externalTransactionId: dataService.userId
        )
    }

    func goToSwap() {
        navigation.send(.swap)
        analyticsManager.log(event: AmplitudeEvent.sellSorryMinAmountSwap)
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
