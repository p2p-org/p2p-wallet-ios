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

    private let transactionDetailsSubject = PassthroughSubject<Void, Never>()
    var transactionDetails: AnyPublisher<SolendTransactionDetailsCoordinator.Strategy, Never> {
        transactionDetailsSubject.map { self.strategy == .withdraw ? .withdraw : .deposit }.eraseToAnyPublisher()
    }

    private let tokenSelectSubject = PassthroughSubject<[Any], Never>()
    var tokenSelect: AnyPublisher<[Any], Never> {
        tokenSelectSubject.eraseToAnyPublisher()
    }

    private let aboutSolendSubject = PassthroughSubject<Void, Never>()
    var aboutSolend: AnyPublisher<Void, Never> { aboutSolendSubject.eraseToAnyPublisher() }

    var symbolSelected = PassthroughSubject<String, Never>()
    private let finishSubject = PassthroughSubject<Void, Never>()
    var finish: AnyPublisher<Void, Never> { finishSubject.eraseToAnyPublisher() }

    @Injected private var notificationService: NotificationService
    @Injected private var priceService: PricesServiceType
    @Injected private var walletRepository: WalletsRepository

    @Published var focusSide: DepositWithdrawInputViewActiveSide = .left
    /// Is loading fees
    @Published var loading: Bool = false
    @Published var lock: Bool = false
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
    @Published var maxTokenDigits: UInt = 9
    var showAbout: Bool {
        strategy == .deposit
    }

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

    var amountTitle: String {
        strategy == .deposit ? L10n.enterTheAmount : L10n.youWillWithdraw
    }

    var useMaxTitle: String {
        strategy == .deposit ? L10n.useAll : L10n.withdrawAll
    }

    var detailItem = CurrentValueSubject<SolendTransactionDetailsView.Model?, Never>(nil)

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
        maxText = useMaxTitle + " \(maxAmount().tokenAmount(symbol: invest.asset.symbol))"

        symbolSelected.combineLatest(
            dataService.availableAssets,
            dataService.marketInfo,
            dataService.deposits
        ) { (
            symbol: String,
            assets: [SolendConfigAsset]?,
            marketInfo: [SolendMarketInfo]?,
            deposits: [SolendUserDeposit]?
        ) -> Invest? in
            guard let asset = assets?.first(where: { $0.symbol == symbol }) else { return nil }
            return (
                asset: asset,
                market: marketInfo?.first(where: { $0.symbol == symbol }),
                userDeposit: deposits?.first(where: { $0.symbol == symbol })
            )
        }
        .compactMap { $0 }
        .handleEvents(receiveOutput: { [weak self] asset in
            DispatchQueue.main.async {
                self?.inputToken = "0"
                self?.maxTokenDigits = UInt(self?.invest.asset.decimals ?? 9)
            }
        })
        .receive(on: RunLoop.main)
        .assign(to: \.invest, on: self)
        .store(in: &subscriptions)

        symbolSelected.combineLatest(dataService.deposits)
            .sink { [weak self] (_: String, deposits: [SolendUserDeposit]?) in
                guard let self = self else { return }
                let deposit = deposits?.first { $0.symbol == self.invest.asset.symbol }
                self.invest.userDeposit = deposit
                self.maxText = self.useMaxTitle + " \(self.maxAmount().tokenAmount(symbol: self.invest.asset.symbol))"
            }
            .store(in: &subscriptions)

        symbolSelected
            .combineLatest(
                dataService.availableAssets,
                dataService.marketInfo,
                dataService.deposits
            ).map {(
                _: String,
                assets: [SolendConfigAsset]?,
                marketInfo: [SolendMarketInfo]?,
                userDeposits: [SolendUserDeposit]?
            ) -> [Invest] in
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

        symbolSelected.send(invest.asset.symbol)

        bind()
    }

    private func bind() {
        $inputToken
            .map { self.maxAmount() >= Double($0) && Double($0) > 0 }
            .assign(to: \.isButtonEnabled, on: self)
            .store(in: &subscriptions)

        $inputFiat
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .filter { _ in self.focusSide == .right }
            .map {
                if self.tokenFiatPrice > 0 {
                    return self.fiatToToken(amount: $0.fiatFormat.double ?? 0)
                        .toString(maximumFractionDigits: self.invest.asset.decimals)
                } else {
                    return "0"
                }
            }
            .assign(to: \.inputToken, on: self)
            .store(in: &subscriptions)

        $inputToken
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .map { Double($0.cryptoCurrencyFormat) ?? 0 }
            .removeDuplicates()
            .handleEvents(receiveOutput: { [weak self] tokenAmount in
                guard let self = self else { return }
                let maxAmount = self.maxAmount()
                let inputLamport = self.lamportFrom(amount: tokenAmount)
                self.loading = true
                self.detailItem.send(nil)
                if self.focusSide == .left {
                    if self.tokenFiatPrice > 0, inputLamport > 0 {
                        self.inputFiat = self.tokenToAmount(amount: tokenAmount).toString(maximumFractionDigits: 2)
                    } else {
                        self.inputFiat = "0"
                    }
                }

                self.hasError = false
                self.isUsingMax = false
                self.buttonText = L10n.enterTheAmount
                if maxAmount < inputLamport.convertToBalance(decimals: self.invest.asset.decimals) {
                    self
                        .buttonText =
                        "\(L10n.maxAmountIs) \(maxAmount.tokenAmount(symbol: self.invest.asset.symbol))"
                    self.feeText = L10n.enterTheCorrectAmountToContinue
                    self.hasError = true
                    self.loading = false
                } else {
                    self.feeText = self.defaultFeeText()
                }
                if self.lamportFrom(amount: maxAmount) == inputLamport {
                    self.isUsingMax = true
                }
                self.inputLamport = inputLamport
            })
            .map { [weak self] val -> AnyPublisher<SolendDepositFee?, Never> in
                if self?.strategy == .withdraw {
                    return Just(nil).eraseToAnyPublisher()
                }
                guard let lamports = self?.lamportFrom(amount: val),
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
                    let (totalAmountLamports1, overflow1) = self.inputLamport.subtractingReportingOverflow(fee.fee)
                    let (totalAmountLamports, overflow2) = totalAmountLamports1.subtractingReportingOverflow(fee.rent)
                    if overflow1 || overflow2 {
                        self.hasError = true
                        self
                            .buttonText =
                            "MIN amount is \(self.amountFrom(lamports: fee.fee + fee.rent).tokenAmount(symbol: self.invest.asset.symbol))"
                        self.isButtonEnabled = false
                        return
                    }
                    let tokenAmount = self.amountFrom(lamports: totalAmountLamports)
                    let fiatAmount = self.tokenToAmount(amount: self.amountFrom(lamports: totalAmountLamports))
                    let amountText = tokenAmount.tokenAmount(symbol: self.invest.asset.symbol) + " (" + fiatAmount
                        .fiatAmount(currency: self.fiat) + ")"
                    self.feeText = "\(L10n.excludingFeesYouLlDeposit) \(amountText)"
                    self.detailItem.send(
                        .init(
                            amount: tokenAmount,
                            fiatAmount: fiatAmount,
                            transferFee: self.amountFrom(lamports: fee.fee),
                            fiatTransferFee: self.tokenToAmount(amount: self.amountFrom(lamports: fee.fee)),
                            fee: self.amountFrom(lamports: fee.rent),
                            fiatFee: self.tokenToAmount(amount: self.amountFrom(lamports: fee.rent)),
                            total: self.amountFrom(lamports: totalAmountLamports),
                            fiatTotal: self.tokenToAmount(amount: self.amountFrom(lamports: totalAmountLamports)),
                            symbol: self.invest.asset.symbol,
                            feeSymbol: self.invest.asset.symbol
                        )
                    )
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
        strategy == .deposit ? (currentWallet?.amount ?? 0) :
        Double(invest.userDeposit?.depositedAmount ?? "0") ?? 0
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

    private func action(lamports: UInt64) async {
        lock = true
        if strategy == .deposit {
            await deposit(lamports: lamports)
        } else {
            await withdraw(lamports: lamports)
        }
        lock = false
        finishSubject.send()
    }

    private func deposit(lamports: UInt64) async {
        guard loading == false, lamports > 0 else { return }

        notificationService.showInAppNotification(.done(L10n.SendingYourDepositToSolend.justWaitUntilItSDone))
        do {
            loading = true
            defer { loading = false }
            try await actionService.deposit(amount: lamports, symbol: invest.asset.symbol)
        } catch {
            notificationService.showInAppNotification(.error(L10n.thereWasAProblemDepositingFunds))
        }
    }

    private func withdraw(lamports: UInt64) async {
        guard loading == false, lamports > 0 else { return }

        notificationService.showInAppNotification(.done(L10n.WithdrawingYourFundsFromSolend.justWaitUntilItSDone))
        do {
            loading = true
            defer { loading = false }
            try await actionService.withdraw(amount: inputLamport, symbol: invest.asset.symbol)
        } catch {
            print(error)
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
        inputToken = maxAmount().toString(maximumFractionDigits: Int(maxTokenDigits))
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
        transactionDetailsSubject.send()
    }

    // MARK: -

    private func formatApy(_ apy: String) -> String {
        guard let apyDouble = Double(apy) else { return "" }
        return "\(apyDouble.fixedDecimal(2))%"
    }

    func showAboutSolend() {
        aboutSolendSubject.send()
    }
}

extension DepositSolendViewModel {
    enum Strategy {
        case deposit
        case withdraw
    }
}
