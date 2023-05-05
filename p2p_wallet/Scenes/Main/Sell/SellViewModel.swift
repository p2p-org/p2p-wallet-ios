import AnalyticsManager
import Combine
import Foundation
import Combine
import Reachability
import Resolver
import KeyAppUI
import SolanaSwift
import Sell
import KeyAppBusiness

enum SellViewModelInputError: Error, Equatable {
    case amountIsTooSmall(minBaseAmount: Double?, baseCurrencyCode: String)
    case exceedsProviderLimit(maxBaseProviderAmount: Double?, baseCurrencyCode: String)
    
    var recomendation: String {
        switch self {
        case .amountIsTooSmall(let minBaseAmount, let baseCurrencyCode):
            return L10n.theMinimumAmountIs(minBaseAmount?.toString() ?? "2", baseCurrencyCode)
        case .exceedsProviderLimit(let maxBaseProviderAmount, let baseCurrencyCode):
            return L10n.theMaximumAmountIs(maxBaseProviderAmount?.toString() ?? "1000", baseCurrencyCode)
        }
    }
}

private let decimals = 2

@MainActor
class SellViewModel: BaseViewModel, ObservableObject {

    // MARK: - Dependencies

    @Injected private var solanaAccountsService: SolanaAccountsService
    @Injected private var dataService: any SellDataService
    @Injected private var actionService: any SellActionService
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var reachability: Reachability
    @Injected private var priceService: PricesService

    // MARK: - Properties

    private let navigation: PassthroughSubject<SellNavigation?, Never>
    private var updatePricesTask: Task<Void, Never>?
    private let goBackSubject = PassthroughSubject<Void, Never>()
    private let presentSOLInfoSubject = PassthroughSubject<Void, Never>()
    var back: AnyPublisher<Void, Never> { goBackSubject.eraseToAnyPublisher() }
    var presentSOLInfo: AnyPublisher<Void, Never> { presentSOLInfoSubject.eraseToAnyPublisher() }

    /// Maximum value to sell from sell provider
    private var maxBaseProviderAmount: Double?
    private var initialBaseAmount: Double?

    // MARK: - Subjects
    @Published var isMoreBaseCurrencyNeeded: Bool = false

    @Published var minBaseAmount: Double? = 2
    @Published var baseCurrencyCode: String = "SOL"
    @Published var baseAmount: Double?
    @Published var maxBaseAmount: Double?
    /// Mostly used to show keyboard
    @Published var isEnteringBaseAmount = false
    @Published var isEnteringQuoteAmount = false

    /// Switcher between TextFields
    @Published var showingBaseAmount: Bool = true {
        didSet {
            isEnteringBaseAmount = showingBaseAmount
            isEnteringQuoteAmount = !showingBaseAmount
        }
    }
    @Published var quoteCurrencyCode: String = Fiat.usd.code
    @Published var quoteAmount: Double?

    @Published var exchangeRate: LoadingValue<Double> = .loaded(0)
    @Published var fee: LoadingValue<SellViewModel.Fee> = .loaded(.zero)
    @Published var status: SellDataServiceStatus = .initialized
    @Published var inputError: SellViewModelInputError?
    var shouldNotShowKeyboard = false
    var currentInputTypeCode: String {
        showingBaseAmount ? baseCurrencyCode : quoteCurrencyCode
    }
    @Published var quoteReceiveAmount: Double = 0

    // MARK: - Initializer

    ///  - parameter initialBaseAmount: value that will be in the field by default
    init(
        initialBaseAmount: Double? = nil,
        navigation: PassthroughSubject<SellNavigation?, Never>
    ) {
        self.navigation = navigation
        self.initialBaseAmount = initialBaseAmount
        self.baseAmount = initialBaseAmount
        super.init()

        warmUp()

        bind()
    }

    // MARK: - Methods

    func goBack() {
        goBackSubject.send()
    }

    func warmUp() {
        Task { [unowned self] in
            await dataService.update()
        }
    }

    /// Sell button action
    func sell() {
        guard Defaults.moonpayInfoShouldHide else {
            shouldNotShowKeyboard = true
            navigation.send(.moonpayInfo)
            return
        }
        openProviderWebView()
    }

    func openProviderWebView() {
        analyticsManager.log(event: .sellAmountNext)
        guard let fiat = dataService.fiat else { return }

        try? openProviderWebView(
            quoteCurrencyCode: fiat.code,
            baseCurrencyAmount: baseAmount?.rounded(decimals: 2) ?? 0,
            externalCustomerId: dataService.userId
        )
    }

    func sellAll() {
        baseAmount = solanaAccountsService.loadedAccounts.first(where: {$0.isNativeSOL})?.amount?.rounded(decimals: decimals, roundingMode: .down) ?? 0
        
        // temporary solution when isEnterQuoteAmount, the quote amount will not be updated when baseAmount changed
        // so we have to release this value
        if isEnteringQuoteAmount {
            isEnteringQuoteAmount = false
        }
    }

    func openProviderWebView(
        quoteCurrencyCode: String,
        baseCurrencyAmount: Double,
        externalCustomerId: String
    ) throws {
        let url = try actionService.createSellURL(
            quoteCurrencyCode: quoteCurrencyCode,
            baseCurrencyAmount: baseCurrencyAmount,
            externalCustomerId: externalCustomerId
        )
        navigation.send(.webPage(url: url))
        shouldNotShowKeyboard = true
    }

    func appeared() {
        guard !shouldPresentInfo() else { return }
        /// Delay before showing keyboard
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.isEnteringBaseAmount = !self.shouldNotShowKeyboard
        }
    }
    
    func moonpayLicenseTap() {
        let url = URL(string: MoonpayLicenseURL)!
        navigation.send(.webPage(url: url))
    }

    // MARK: - Binding

    private func bind() {
        bindData()
        bindInput()
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
                self?.isEnteringQuoteAmount == false // when entering base amount or non of textfield chosen
            }
            .map { baseAmount, exchangeRate in
                guard let baseAmount else {return nil}
                return (baseAmount * exchangeRate.value).rounded(decimals: decimals)
            }
            .assignWeak(to: \.quoteAmount, on: self)
            .store(in: &subscriptions)

        // fill base amount base on quote amount
        Publishers.CombineLatest($quoteAmount, $exchangeRate)
            .filter { [weak self] _ in
                self?.isEnteringQuoteAmount == true
            }
            .map { quoteAmount, exchangeRate in
                guard let quoteAmount, let exchangeRate = exchangeRate.value, exchangeRate != 0 else { return nil }
                return (quoteAmount / exchangeRate).rounded(decimals: decimals)
            }
            .assignWeak(to: \.baseAmount, on: self)
            .store(in: &subscriptions)

        // update prices on base amount change
        $baseAmount
            .removeDuplicates()
            .filter { $0 != nil }
            .withLatestFrom(
                Publishers.CombineLatest(
                    $baseCurrencyCode,
                    $quoteCurrencyCode
                ),
                resultSelector: { baseAmount, el -> (Double?, String, String) in
                    (baseAmount, el.0, el.1)
                }
            )
            .sink { [weak self] baseAmount, baseCurrencyCode, quoteCurrencyCode in
                self?.updateFeesAndExchangeRates(
                    baseAmount: baseAmount,
                    baseCurrencyCode: baseCurrencyCode,
                    quoteCurrencyCode: quoteCurrencyCode
                )
            }
            .store(in: &subscriptions)
    }

    private func bindData() {
        // bind status publisher to status property
        dataService.statusPublisher
            .receive(on: RunLoop.main)
            .assignWeak(to: \.status, on: self)
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
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] currency, fiat in
                guard let self = self else { return }
                self.baseAmount = max(self.initialBaseAmount ?? 0, currency?.minSellAmount ?? 0)
                self.quoteCurrencyCode = fiat?.code ?? "USD"
                self.maxBaseProviderAmount = currency?.maxSellAmount ?? 0
                self.minBaseAmount = currency?.minSellAmount ?? 0
                self.baseCurrencyCode = "SOL"
                self.checkIfMoreBaseCurrencyNeeded()
                self.updateFeesAndExchangeRates(baseAmount: self.baseAmount, baseCurrencyCode: self.baseCurrencyCode, quoteCurrencyCode: self.quoteCurrencyCode)
                self.checkError(amount: self.baseAmount ?? 0)
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
        solanaAccountsService.dataDidChange
            .sink(receiveValue: { [weak self] val in
                self?.checkIfMoreBaseCurrencyNeeded()
            })
            .store(in: &subscriptions)

        // re-calculate fee after every 10 s if no input is active
        Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .withLatestFrom(Publishers.CombineLatest3(
                $baseAmount, $baseCurrencyCode, $quoteCurrencyCode
            ))
            .filter { [weak self] _ in
                self?.status.isReady == true
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] baseAmount, baseCurrencyCode, quoteCurrencyCode in
                self?.updateFeesAndExchangeRates(
                    baseAmount: baseAmount,
                    baseCurrencyCode: baseCurrencyCode,
                    quoteCurrencyCode: quoteCurrencyCode
                )
            }
            .store(in: &subscriptions)

        // analytics
        $status
            .sink { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .error:
                    self.analyticsManager.log(event: .sellClickedServerError)
                case .ready:
                    if self.isMoreBaseCurrencyNeeded {
                        self.analyticsManager.log(event: .sellClickedSorryMinAmount)
                    }
                default:
                    break
                }
            }
            .store(in: &subscriptions)

        try? reachability.startNotifier()
        reachability.status.sink { [unowned self] _ in
            _ = self.reachability.check()
        }.store(in: &subscriptions)
    }

    // MARK: - Helpers

    private func checkIfMoreBaseCurrencyNeeded() {
        maxBaseAmount = solanaAccountsService.loadedAccounts.first(where: {$0.isNativeSOL})?.amount?.rounded(decimals: decimals, roundingMode: .down)
        if maxBaseAmount < minBaseAmount {
            isMoreBaseCurrencyNeeded = true
        }
    }

    private func checkError(amount: Double) {
        inputError = nil
        if maxBaseAmount < minBaseAmount {
            inputError = .amountIsTooSmall(minBaseAmount: minBaseAmount, baseCurrencyCode: baseCurrencyCode)
        } else if amount < minBaseAmount {
            inputError = .amountIsTooSmall(minBaseAmount: minBaseAmount, baseCurrencyCode: baseCurrencyCode)
        } else if amount > maxBaseProviderAmount {
            inputError = .exceedsProviderLimit(
                maxBaseProviderAmount: maxBaseProviderAmount,
                baseCurrencyCode: baseCurrencyCode
            )
        } else if amount > (maxBaseAmount ?? 0) {
            inputError = .amountIsTooSmall(minBaseAmount: minBaseAmount, baseCurrencyCode: baseCurrencyCode)
        }
    }

    private func updateFeesAndExchangeRates(
        baseAmount: Double?,
        baseCurrencyCode: String,
        quoteCurrencyCode: String
    ) {
        updatePricesTask?.cancel()
        fee = .loading
        if exchangeRate.value == nil {
            exchangeRate = .loading
        }

        guard let baseAmount, baseAmount >= minBaseAmount else {
            fee = .loaded(.zero)
            return
        }

        updatePricesTask = Task { [unowned self] in
            // get sellQuote
            do {
                let sellQuote = try await self.actionService.sellQuote(
                    baseCurrencyCode: baseCurrencyCode.lowercased(),
                    quoteCurrencyCode: quoteCurrencyCode.lowercased(),
                    baseCurrencyAmount: baseAmount.rounded(decimals: decimals),
                    extraFeePercentage: 0
                )
                // update data
                await MainActor.run { [weak self] in
                    guard let self,
                          let mint = Token.moonpaySellSupportedTokens
                            .first(where: {$0.symbol == baseCurrencyCode})?
                            .address
                    else { return }
                    let baseCurrencyPrice = max(0.00001, self.priceService.currentPrice(mint: mint)?.value ?? 0)
                    let totalFeeAmount = sellQuote.feeAmount + sellQuote.extraFeeAmount
                    self.fee = .loaded(
                        Fee(
                            baseAmount: (totalFeeAmount) / baseCurrencyPrice,
                            quoteAmount: totalFeeAmount
                        )
                    )
                    self.exchangeRate = .loaded(sellQuote.baseCurrencyPrice)
                    self.quoteReceiveAmount = max(0, (quoteAmount ?? 0) - totalFeeAmount)
                }
            } catch {
                // update data
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    if reachability.connection != .unavailable {
                        self.fee = .error(error)
                    } else {
                        self.fee = .loaded(self.fee.value ?? .zero)
                    }
                    if exchangeRate.value == nil {
                        self.exchangeRate = .error(error)
                    }
                }
            }
        }
    }

    private func shouldPresentInfo() -> Bool {
        guard !Defaults.isSellInfoPresented else { return false }
        presentSOLInfoSubject.send(())
        Defaults.isSellInfoPresented = true
        return true
    }
}

extension SellViewModel {
    struct Fee {
        var baseAmount: Double
        var quoteAmount: Double

        static let zero = SellViewModel.Fee(baseAmount: 0, quoteAmount: 0)
    }
}
