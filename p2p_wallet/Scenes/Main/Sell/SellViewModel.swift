import AnalyticsManager
import Combine
import Foundation
import Combine
import Resolver
import RxSwift
import KeyAppUI
import SolanaSwift
import Sell
import Send

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

private let decimals = 2

@MainActor
class SellViewModel: BaseViewModel, ObservableObject {

    // MARK: - Dependencies

    @Injected private var walletRepository: WalletsRepository
    @Injected private var dataService: any SellDataService
    @Injected private var actionService: any SellActionService
    @Injected private var analyticsManager: AnalyticsManager

    // MARK: - Properties

    private let navigation: PassthroughSubject<SellNavigation?, Never>
    private var updatePricesTask: Task<Void, Never>?
    private let goBackSubject = PassthroughSubject<Void, Never>()
    var back: AnyPublisher<Void, Never> { goBackSubject.eraseToAnyPublisher() }
    private let transactionRemovedSubject = PassthroughSubject<Void, Never>()
    var transactionRemoved: AnyPublisher<Void, Never> { transactionRemovedSubject.eraseToAnyPublisher() }
    private let cashOutInteruptedSubject = PassthroughSubject<Void, Never>()
    var cashOutInterupted: AnyPublisher<Void, Never> { cashOutInteruptedSubject.eraseToAnyPublisher() }

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
    
    @Published var exchangeRate: LoadingValue<Double> = .loaded(0)
    @Published var fee: LoadingValue<Double> = .loaded(0)
    @Published var status: SellDataServiceStatus = .initialized
    @Published var inputError: SellViewModelInputError?
    
    @Published var isShowingAlert: Bool = false
    
    @Published var incompletedTransactions = [SellDataServiceTransaction]()

    // MARK: - Initializer

    init(navigation: PassthroughSubject<SellNavigation?, Never>) {
        self.navigation = navigation
        super.init()

        warmUp()

        bind()
    }

    // MARK: - Methods
    
    func interuptCashOut() {
        cashOutInteruptedSubject.send()
    }

    func goBack() {
        goBackSubject.send()
    }

    func warmUp() {
        Task { [unowned self] in
            await dataService.update()
        }
    }
    
    func sell() {
        analyticsManager.log(event: AmplitudeEvent.sellAmountNext)
        guard let fiat = dataService.fiat else { return }

        try? openProviderWebView(
            quoteCurrencyCode: fiat.code,
            baseCurrencyAmount: baseAmount?.rounded(decimals: 2) ?? 0,
            externalCustomerId: dataService.userId
        )
    }

    func goToSwap() {
        navigation.send(.swap)
        analyticsManager.log(event: AmplitudeEvent.sellSorryMinAmountSwap)
    }

    func sellAll() {
        baseAmount = walletRepository.nativeWallet?.amount?.rounded(decimals: decimals, roundingMode: .down) ?? 0
        
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
            .assign(to: \.quoteAmount, on: self)
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
            .assign(to: \.baseAmount, on: self)
            .store(in: &subscriptions)
        
        // update prices on base amount change
        $baseAmount
            .removeDuplicates()
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
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] currency, fiat in
                guard let self = self else { return }
                self.baseAmount = currency?.minSellAmount ?? 0
                self.quoteCurrencyCode = fiat?.code ?? "USD"
                self.maxBaseProviderAmount = currency?.maxSellAmount ?? 0
                self.minBaseAmount = currency?.minSellAmount ?? 0
                self.baseCurrencyCode = "SOL"
                self.checkIfMoreBaseCurrencyNeeded()
                self.updateFeesAndExchangeRates(baseAmount: self.baseAmount, baseCurrencyCode: self.baseCurrencyCode, quoteCurrencyCode: self.quoteCurrencyCode)
            })
            .store(in: &subscriptions)

        // Open pendings in case there are pending txs
        dataPublisher
            .withLatestFrom(dataService.transactionsPublisher)
            .map { $0.filter { $0.status == .waitingForDeposit }}
            .removeDuplicates()
            .assign(to: \.incompletedTransactions, on: self)
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
        
        // re-calculate fee after every 10 m if no input is active
        Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .withLatestFrom(Publishers.CombineLatest3(
                $baseAmount, $baseCurrencyCode, $quoteCurrencyCode
            ))
            .filter { [weak self] _ in
                self?.status.isReady == true &&
                self?.isEnteringBaseAmount == false &&
                self?.isEnteringQuoteAmount == false
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
                switch status {
                case .error:
                    self?.analyticsManager.log(event: AmplitudeEvent.sellClickedSorryMinAmount)
                default:
                    break
                }
            }
            .store(in: &subscriptions)
    }
    
    // MARK: - SellPendingViewModel

    func createSellPendingViewModel(transaction: SellDataServiceTransaction) -> SellPendingViewModel? {
        guard let fiat = dataService.fiat else {
            return nil
        }
        // create viewModel, viewController and push to navigation stack
        let tokenSymbol = "SOL"
        let viewModel = SellPendingViewModel(
            model: SellPendingViewModel.Model(
                id: transaction.id,
                tokenImage: .solanaIcon,
                tokenSymbol: tokenSymbol,
                tokenAmount: transaction.baseCurrencyAmount,
                fiatAmount: transaction.quoteCurrencyAmount,
                currency: fiat,
                receiverAddress: transaction.depositWallet
            )
        )
        
        // observe viewModel's event
        viewModel.transactionRemoved
            .sink { [weak self] in
                self?.transactionRemovedSubject.send()
            }
            .store(in: &subscriptions)

        viewModel.back
            .sink(receiveValue: { [weak self] in
                self?.isShowingAlert = true
            })
            .store(in: &subscriptions)

        viewModel.send
            .sink(receiveValue: {[weak self] in
                guard let self, let wallet = self.walletRepository.nativeWallet else { return }
                self.navigation.send(
                    .send(
                        from: wallet,
                        to: Recipient(
                            address: transaction.depositWallet,
                            category: .solanaAddress,
                            attributes: [.funds]
                        ),
                        amount: transaction.baseCurrencyAmount,
                        sellTransaction: transaction
                    )
                )
            })
            .store(in: &subscriptions)
        
        return viewModel
    }
    
    // MARK: - Helpers

    private func checkIfMoreBaseCurrencyNeeded() {
        maxBaseAmount = walletRepository.nativeWallet?.amount?.rounded(decimals: decimals, roundingMode: .down)
        if maxBaseAmount < minBaseAmount {
            isMoreBaseCurrencyNeeded = true
        }
    }

    private func checkError(amount: Double) {
        inputError = nil
        if amount < minBaseAmount {
            inputError = .amountIsTooSmall(minBaseAmount: minBaseAmount, baseCurrencyCode: baseCurrencyCode)
            analyticsManager.log(event: AmplitudeEvent.sellClickedServerError)
        } else if amount > maxBaseProviderAmount {
            inputError = .exceedsProviderLimit(
                maxBaseProviderAmount: maxBaseProviderAmount,
                baseCurrencyCode: baseCurrencyCode
            )
            analyticsManager.log(event: AmplitudeEvent.sellClickedServerError)
        } else if amount > (maxBaseAmount ?? 0) {
            inputError = .insufficientFunds(baseCurrencyCode: baseCurrencyCode)
            analyticsManager.log(event: AmplitudeEvent.sellClickedServerError)
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
        
        guard baseAmount >= minBaseAmount else {
            return
        }
        
        updatePricesTask = Task { [unowned self] in
            // get sellQuote
            guard let baseAmount else {
                return
            }
            do {
                let sellQuote = try await self.actionService.sellQuote(
                    baseCurrencyCode: baseCurrencyCode.lowercased(),
                    quoteCurrencyCode: quoteCurrencyCode.lowercased(),
                    baseCurrencyAmount: baseAmount.rounded(decimals: decimals),
                    extraFeePercentage: 0
                )
                // update data
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.fee = .loaded(sellQuote.feeAmount + sellQuote.extraFeeAmount)
                    self.exchangeRate = .loaded(sellQuote.baseCurrencyPrice)
                }
            } catch {
                print(baseAmount, baseCurrencyCode, quoteCurrencyCode, error)
                // update data
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.fee = .error(error)
                    if exchangeRate.value == nil {
                        self.exchangeRate = .error(error)
                    }
                }
            }
        }
    }
}
