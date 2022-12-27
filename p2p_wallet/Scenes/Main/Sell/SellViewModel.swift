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

    // MARK: - Properties

    /// Maximum value to sell from sell provider
    private var maxBaseProviderAmount: Double?

    // MARK: - Subjects
    @Published var isMoreBaseCurrencyNeeded: Bool = false

    @Published var minBaseAmount: Double?
    @Published var baseCurrencyCode: String = "SOL"
    @Published var baseAmount: Double?
    @Published var maxBaseAmount: Double?
    @Published var isEnteringBaseAmount: Bool = true
    
    @Published var quoteCurrencyCode: String = Fiat.usd.code
    @Published var quoteAmount: Double?
    @Published var isEnteringQuoteAmount: Bool = false
    
    @Published var exchangeRate: Double = 0
    @Published var fee: Double = 0
    @Published var status: SellDataServiceStatus = .initialized
    @Published var inputError: SellViewModelInputError?

    // MARK: - Initializer

    init(navigation: PassthroughSubject<SellNavigation?, Never>) {
        self.navigation = navigation
        super.init()

        warmUp()

        bind()
    }

    // MARK: - Methods

    func warmUp() {
        Task { [unowned self] in
            await dataService.update()
        }
    }
    
    // MARK: - Binding
    
    private func bind() {
        bindInput()
        bindData()
    }
    
    private func bindInput() {
        // verify base amount
        $baseAmount
            .sink { [weak self] amount in
                self?.checkError(amount: amount ?? 0)
            }
            .store(in: &subscriptions)
        
        // fill quote amount base on base amount
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

        // fill base amount base on quote amount
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
    }
    
    private func bindData() {
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
        
        // re-calculate fee after every 10 m
        let sellQuotePublisher = Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .withLatestFrom(Publishers.CombineLatest3(
                $baseAmount, $baseCurrencyCode, $quoteCurrencyCode
            ))
            .filter { [weak self] _ in self?.status.isReady == true }
            .asyncMap { [weak self] amount, base, quote -> SellActionServiceQuote? in
                guard let self, let amount else { return nil }
                let sellQuote = try? await self.actionService.sellQuote(
                    baseCurrencyCode: base.lowercased(),
                    quoteCurrencyCode: quote.lowercased(),
                    baseCurrencyAmount: amount.rounded(decimals: 2),
                    extraFeePercentage: 0
                )
                return sellQuote ?? nil
            }
        
        sellQuotePublisher
            .map { $0?.feeAmount + $0?.extraFeeAmount }
            .assign(to: \.fee, on: self)
            .store(in: &subscriptions)
        
        sellQuotePublisher
            .map { $0?.baseCurrencyPrice ?? 0 }
            .assign(to: \.exchangeRate, on: self)
            .store(in: &subscriptions)
        
        // analytics
        $status
            .sink { [weak self] status in
                switch status {
                case .error:
                    self?.analyticsManager.log(event: AmplitudeEvent.sellClickedSorryMinAmount)
                default:
                    break
                }
            }
            .store(in: &subscriptions)
    }
    
    private func checkIfMoreBaseCurrencyNeeded() {
        maxBaseAmount = walletRepository.nativeWallet?.amount
        if maxBaseAmount < minBaseAmount {
            isMoreBaseCurrencyNeeded = true
        }
    }

    private func checkError(amount: Double) {
        inputError = nil
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
