import Combine
import FeeRelayerSwift
import Foundation
import Resolver
import SolanaSwift
import Solend

@MainActor
class DepositSolendViewModel: ObservableObject {
    private let strategy: Strategy
    private let dataService: SolendDataService
    private let actionService: SolendActionService
    private var subscriptions = Set<AnyCancellable>()
    private var market: [Invest] = []

    private let transactionDetailsSubject = PassthroughSubject<SolendTransactionDetailsView.Model, Never>()
    var transactionDetails: AnyPublisher<SolendTransactionDetailsView.Model, Never> {
        transactionDetailsSubject.eraseToAnyPublisher()
    }

    private let tokenSelectSubject = PassthroughSubject<[Any], Never>()
    var tokenSelect: AnyPublisher<[Any], Never> {
        tokenSelectSubject.eraseToAnyPublisher()
    }

    @Injected private var notificationService: NotificationService
    @Injected private var priceService: PricesServiceType
    @Injected private var walletRepository: WalletsRepository

    @Published var focusSide: DepositWithdrawInputViewActiveSide = .left
    /// Is loading fees
    @Published var loading: Bool = false
    @Published var inputToken: String = "0"
    @Published var inputFiat: String = "0"
    @Published var fiat: Fiat = Defaults.fiat
    @Published var invest: Invest
    @Published var depositFee: SolendDepositFee?
    @Published var inputLamport: UInt64 = 0
    @Published var isButtonEnabled: Bool = false
    @Published var buttonText: String = L10n.enterTheAmount
    @Published var hasError = false
    @Published var feeText = ""
    @Published var maxText = "Use all"
    @Published var isUsingMax = false
    /// Deposit slider position
    @Published var isSliderOn = false

    var sliderTitle: String {
        strategy == .deposit ? L10n.slideToDeposit : L10n.slideToWithdraw
    }

    var headerViewTitle: String {
        maxAmount().tokenAmount(symbol: invest.asset.symbol)
    }

    var headerViewSubtitle: String {
        strategy == .deposit ?
            invest.asset.name :
            L10n.yielding + " \(formatApy(invest.market?.supplyInterest ?? "")) APY"
    }

    var headerViewRightTitle: String {
        strategy == .deposit ?
            "\(formatApy(invest.market?.supplyInterest ?? ""))" :
            tokenToAmount(amount: maxAmount()).fiatAmount(currency: fiat)
    }

    var headerViewRightSubtitle: String? {
        strategy == .deposit ? "APY" : nil
    }

    var headerViewLogo: String? {
        invest.asset.logo
    }

    var title: String {
        strategy == .deposit ? L10n.depositIntoSolend : L10n.withdrawFunds
    }

    var detailItem: SolendTransactionDetailsView.Model {
        .init(strategy: strategy == .deposit ? .deposit : .withdraw,
              amount: 1,
              fiatAmount: 2,
              transferFee: 3,
              fiatTransferFee: 4,
              fee: 5,
              fiatFee: 6,
              total: 7,
              fiatTotal: inputFiat.fiatFormat.double ?? 0,
              symbol: invest.asset.symbol,
              feeSymbol: invest.asset.symbol)
    }

    /// Balance for selected Token
    private var currentWallet: Wallet? {
        walletRepository.getWallets().filter { $0.token.address == self.invest.asset.mintAddress }.first
    }

    /// Rate for selected pair Token -> Fiat
    private var tokenFiatPrice: Double?

    init(
        strategy: Strategy = .deposit,
        initialAsset: SolendConfigAsset,
        mocked: Bool = false
    ) throws {
        self.strategy = strategy
        dataService = mocked ? SolendDataServiceMock() : Resolver.resolve(SolendDataService.self)
        actionService = mocked ? SolendActionServiceMock() : Resolver.resolve(SolendActionService.self)
        invest = (asset: initialAsset, market: nil, userDeposit: nil)
        tokenFiatPrice = priceService.currentPrice(for: invest.asset.symbol)?.value

        feeText = defaultFeeText()
        maxText = L10n.useAll + " \(maxAmount().tokenAmount(symbol: invest.asset.symbol))"

        dataService.marketInfo
            .sink { [weak self] markets in
                guard let self = self else { return }
                let marketInfo = markets?.first { $0.symbol == self.invest.asset.symbol }
                self.invest.market = marketInfo
            }
            .store(in: &subscriptions)

        dataService.deposits
            .sink { [weak self] deposits in
                guard let self = self else { return }
                let deposit = deposits?.first { $0.symbol == self.invest.asset.symbol }
                self.invest.userDeposit = deposit
                self.maxText = L10n.useAll + " \(self.maxAmount().tokenAmount(symbol: self.invest.asset.symbol))"
            }
            .store(in: &subscriptions)

        dataService.availableAssets
            .combineLatest(dataService.marketInfo, dataService.deposits)
            .map { (assets: [SolendConfigAsset]?, marketInfo: [SolendMarketInfo]?, userDeposits: [SolendUserDeposit]?) -> [Invest] in
                guard let assets = assets else { return [] }
                return assets.map { asset -> Invest in
                    (
                        asset: asset,
                        market: marketInfo?.first(where: { $0.symbol == asset.symbol }),
                        userDeposit: userDeposits?.first(where: { $0.symbol == asset.symbol })
                    )
                }.sorted { (v1: Invest, v2: Invest) -> Bool in
                    let apy1: Double = .init(v1.market?.supplyInterest ?? "") ?? 0
                    let apy2: Double = .init(v2.market?.supplyInterest ?? "") ?? 0
                    return apy1 > apy2
                }
            }
            .receive(on: RunLoop.main)
            .assign(to: \.market, on: self)
            .store(in: &subscriptions)
        bind()
    }

    private func bind() {
        $inputToken
            .map { self.maxAmount() >= Double($0) && Double($0) > 0 }
            .assign(to: \.isButtonEnabled, on: self)
            .store(in: &subscriptions)

        Publishers.CombineLatest(
            $inputToken.map { Double($0.cryptoCurrencyFormat) ?? 0 }.removeDuplicates(),
            $inputFiat.map { Double($0.fiatFormat) ?? 0 }.removeDuplicates()
        )
            .handleEvents(receiveOutput: { [weak self] val in
                guard let self = self else { return }
                let tokenAmount = Double(val.0)
                let fiatAmount = Double(val.1)
                let maxAmount = self.maxAmount()
                self.inputLamport = self.lamportFrom(amount: tokenAmount)
                self.loading = true
                if self.focusSide == .left { // editing token
                    if self.tokenFiatPrice > 0, self.inputLamport > 0 {
                        self.inputFiat = self.tokenToAmount(amount: tokenAmount).toString(maximumFractionDigits: 2)
                    } else {
                        self.inputFiat = "0"
                    }
                } else {
                    if self.tokenFiatPrice > 0 {
                        self.inputToken = self.fiatToToken(amount: fiatAmount).toString(maximumFractionDigits: 9)
                    } else {
                        self.inputToken = "0"
                    }
                }

                self.hasError = false
                self.isUsingMax = false
                if maxAmount < self.inputLamport.convertToBalance(decimals: self.invest.asset.decimals) {
                    self
                        .buttonText =
                        "\(L10n.maxAmountIs) \(maxAmount.tokenAmount(symbol: self.invest.asset.symbol))"
                    self.feeText = L10n.enterTheCorrectAmountToContinue
                    self.hasError = true
                    self.loading = false
                } else {
                    self.feeText = self.defaultFeeText()
                }
                if maxAmount == self.inputLamport.convertToBalance(decimals: self.invest.asset.decimals) {
                    self.isUsingMax = true
                }
            })
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .map { [weak self] val -> AnyPublisher<SolendDepositFee?, Never> in
                if self?.strategy == .withdraw {
                    return Just(nil).eraseToAnyPublisher()
                }
                guard let lamports = self?.lamportFrom(amount: Double(val.0)),
                      let self = self,
                      lamports > 0,
                      !self.hasError else { return Just(nil).eraseToAnyPublisher() }

                return self.calculateFee(
                    inputInLamports: lamports,
                    symbol: self.invest.asset.symbol
                )
                    .map(Optional.init)
                    .replaceError(with: nil)
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .sink(receiveValue: { [weak self] fee in
                guard let self = self else { return }
                self.loading = false
                if let fee = fee {
                    let totalAmountLamports = self.inputLamport.subtractingReportingOverflow(fee.fee).partialValue
                    let fiatAmount = self.tokenToAmount(amount: self.amountFrom(lamports: totalAmountLamports))
                    let amountText =
                        "\(self.amountFrom(lamports: totalAmountLamports).tokenAmount(symbol: self.invest.asset.symbol)) (\(fiatAmount.fiatAmount(currency: self.fiat)))"
                    self.feeText = "\(L10n.excludingFeesYouWillDeposit) \(amountText)"
                }
            })
            .store(in: &subscriptions)

        $isSliderOn.filter { $0 }
            .sink { [weak self] _ in
                guard let inputLamport = self?.inputLamport else { return }
                Task {
                    do {
                        try await self?.action(lamports: inputLamport)
                    } catch {
                        self?.isSliderOn = false
                        debugPrint(error)
                    }
                }
            }.store(in: &subscriptions)
    }

    // MARK: -

    func maxAmount() -> Double {
        strategy == .deposit ? (currentWallet?.amount ?? 0) : Double(invest.userDeposit?.depositedAmount ?? "0") ?? 0
    }

    func defaultFeeText() -> String {
        strategy == .deposit ? L10n.withdrawYourFundsWithAllRewardsAtAnyTime : L10n
            .aProportionalAmountOfRewardsWillBeWithdrawn
    }

    // MARK: - Conversion

    func lamportFrom(amount: Double) -> UInt64 {
        UInt64(amount * pow(10, Double(invest.asset.decimals)))
    }

    func amountFrom(lamports: UInt64) -> Double {
        Double(lamports) / pow(10, Double(invest.asset.decimals))
    }

    func fiatToToken(amount: Double) -> Double {
        guard let tokenFiatPrice = tokenFiatPrice else { return 0 }
        return amount / tokenFiatPrice
    }

    func tokenToAmount(amount: Double) -> Double {
        (tokenFiatPrice ?? 0) * amount
    }

    // MARK: - Action

    private func action(lamports: UInt64) async throws {
        if strategy == .deposit {
            try await deposit(lamports: lamports)
        } else {
            try await withdraw(lamports: lamports)
        }
    }

    private func deposit(lamports: UInt64) async throws {
        guard loading == false, lamports > 0 else { return }

        notificationService.showInAppNotification(.done(L10n.SendingYourDepositToSolend.justWaitUntilItSDone))
        do {
            loading = true
            defer { loading = false }
            try await actionService.deposit(amount: lamports, symbol: invest.asset.symbol)
            notificationService.showInAppNotification(.done(L10n.theFundsHaveBeenDepositedSuccessfully))
        } catch {
            notificationService.showInAppNotification(.error(L10n.thereWasAProblemDepositingFunds))
        }
    }

    private func withdraw(lamports: UInt64) async throws {
        guard loading == false, lamports > 0 else { return }

        notificationService.showInAppNotification(.done(L10n.WithdrawingYourFundsFromSolend.justWaitUntilItSDone))
        do {
            loading = true
            defer { loading = false }
            try await actionService.withdraw(amount: inputLamport, symbol: invest.asset.symbol)
            notificationService.showInAppNotification(.done(L10n.theFundsHaveBeenWithdrawnSuccessfully))
        } catch {
            notificationService.showInAppNotification(.error(L10n.thereWasAProblemWithdrawingFunds))
        }
    }

    private func calculateFee(inputInLamports: UInt64, symbol: String) -> AnyPublisher<SolendDepositFee, Error> {
        Deferred {
            Future<SolendDepositFee, Error> { promise in
                Task {
                    do {
                        let result = try await self.actionService.depositFee(amount: inputInLamports, symbol: symbol)
                        promise(.success(result))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }

    // MARK: -

    func useMaxTapped() {
        focusSide = .left
        inputToken = maxAmount().toString(maximumFractionDigits: 9)
    }

    func headerTapped() {
        if strategy == .deposit {
            tokenSelectSubject.send(
                market
                    .compactMap { asset, market, _ in
                        let wallet = walletRepository.getWallets()
                            .first { wallet in
                                wallet.amount > 0 && market?.symbol == wallet.token.symbol
                            }
                        if let newWallet = wallet {
                            return TokenToDepositView.Model(
                                amount: newWallet.amount,
                                imageUrl: URL(string: asset.logo ?? ""),
                                symbol: newWallet.token.symbol,
                                name: newWallet.token.name,
                                apy: market?.supplyInterest.double ?? 0
                            )
                        }
                        return nil
                    }
            )
        } else {
            tokenSelectSubject.send(
                market
                    .filter { $2 != nil }
                    .map { asset, market, userDeposit in
                        TokenToWithdrawView.Model(
                            amount: userDeposit?.depositedAmount.double,
                            imageUrl: URL(string: asset.logo ?? ""),
                            symbol: userDeposit?.symbol ?? "",
                            fiatAmount: userDeposit?.depositedAmount.double * priceService
                                .currentPrice(for: userDeposit?.symbol ?? "")?.value,
                            apy: market?.supplyInterest.double ?? 0
                        )
                    }
            )
        }
    }

    func showDetailTapped() {
        transactionDetailsSubject.send(detailItem)
    }

    // MARK: -

    private func formatApy(_ apy: String) -> String {
        guard let apyDouble = Double(apy) else { return "" }
        return "\(apyDouble.fixedDecimal(2))%"
    }
}

extension DepositSolendViewModel {
    enum Strategy {
        case deposit
        case withdraw
    }
}
