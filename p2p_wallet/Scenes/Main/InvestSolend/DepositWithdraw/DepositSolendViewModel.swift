import Combine
import FeeRelayerSwift
import Foundation
import Resolver
import SolanaSwift
import Solend
import Sentry

enum DepositSolendViewModelError {
    case invalidFeePayer
}

@MainActor
class DepositSolendViewModel: ObservableObject {
    private let strategy: Strategy
    private let dataService: SolendDataService
    private let actionService: SolendActionService
    private let feePayingStrategy: [Strategy: SolendFeePayingStrategy] = [
        .deposit: DefaultSolendDepositFeePayingStrategy(
            orca: Resolver.resolve(),
            actionService: Resolver.resolve(),
            wallets: Resolver.resolve()
        ),
        .withdraw: DefaultSolendWithdrawFeePayingStrategy(
            orca: Resolver.resolve(),
            actionService: Resolver.resolve(),
            wallets: Resolver.resolve()
        ),
    ]
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
    @Published var depositFee: SolendFeePaying?
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
    @Published var showHeaderDisclosure = true
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
            L10n.yielding + " \((invest.market?.supplyInterest ?? "0").formatApy) APY"
    }

    var headerViewRightTitle: String {
        strategy == .deposit ?
            "\((invest.market?.supplyInterest ?? "0").formatApy)" :
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

        symbolSelected
            .combineLatest(
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
            .handleEvents(receiveOutput: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.inputToken = "0"
                    self?.maxTokenDigits = UInt(self?.invest.asset.decimals ?? 9)
                    if strategy == .withdraw {
                        self?.showHeaderDisclosure = (self?.market.filter { $2 != nil }.count ?? 0 > 1)
                    } else {
                        self?.showHeaderDisclosure = self?.availableDepositModels().count ?? 0 > 1
                    }
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
                DispatchQueue.main.async {
                    self.maxText = self
                        .useMaxTitle + " \(self.maxAmount().tokenAmount(symbol: self.invest.asset.symbol))"
                }
            }
            .store(in: &subscriptions)

        symbolSelected
            .combineLatest(
                dataService.availableAssets,
                dataService.marketInfo,
                dataService.deposits
            )
            .map { (
                _: String,
                assets: [SolendConfigAsset]?,
                marketInfo: [SolendMarketInfo]?,
                userDeposits: [SolendUserDeposit]?
            ) -> [Invest] in
                guard let assets = assets else { return [] }
                return assets.map { asset -> Invest in
                    (asset: asset,
                     market: marketInfo?.first(where: { $0.symbol == asset.symbol }),
                     userDeposit: userDeposits?.first(where: { $0.symbol == asset.symbol }))
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
            .map { [weak self] in self?.maxAmount() >= Double($0) && Double($0) > 0 }
            .assign(to: \.isButtonEnabled, on: self)
            .store(in: &subscriptions)

        $inputFiat
            .debounce(for: .seconds(0.0), scheduler: DispatchQueue.main)
            .filter { [weak self] _ in self?.focusSide == .right }
            .map { [weak self] in
                if self?.tokenFiatPrice > 0 {
                    return self?.fiatToToken(amount: $0.fiatFormat.double ?? 0)
                        .toString(maximumFractionDigits: self?.invest.asset.decimals ?? 9) ?? ""
                } else {
                    return "0"
                }
            }
            .assign(to: \.inputToken, on: self)
            .store(in: &subscriptions)

        $inputToken
            .debounce(for: .seconds(0.0), scheduler: DispatchQueue.main)
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
            .map { [weak self] val -> AnyPublisher<SolendFeePaying?, Never> in
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
            .sink(receiveValue: { [weak self] (fee: SolendFeePaying?) in
                guard let self = self else { return }
                self.loading = false
                self.depositFee = fee
                if let fee = fee { self.processFee(fee: fee) }
            })
            .store(in: &subscriptions)

        $isSliderOn.filter { $0 }
            .sink { [weak self] _ in
                guard let inputLamport = self?.inputLamport else { return }
                Task { try await self?.action(lamports: inputLamport) }
            }.store(in: &subscriptions)

        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: nil
        ) { _ in
            DispatchQueue.main.async {
                _ = UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
        }
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: nil
        ) { _ in
            DispatchQueue.main.async {
                self.focusSide = .left
            }
        }
    }

    // MARK: -
    
    func processFee(fee: SolendFeePaying) {
        // Fee
        let transferFee = Double(fee.fee.transaction) / pow(fee.decimals, Double(fee.decimals))
        let fiatTransferFee: Double = transferFee * (self.priceService.currentPrice(for: fee.symbol)?.value ?? 0)
        
        let rentFee = Double(fee.fee.accountBalances) / pow(fee.decimals, Double(fee.decimals))
        let fiatRentFee: Double = rentFee * (self.priceService.currentPrice(for: fee.symbol)?.value ?? 0)

        // Total
        var total: Lamports = self.inputLamport
        var fiatTotal: Double = self.tokenToAmount(amount: self.amountFrom(lamports: total))
        
        if invest.asset.symbol == fee.symbol {
            total = total + fee.fee.transaction + fee.fee.accountBalances
            fiatTotal = self.tokenToAmount(amount: self.amountFrom(lamports: total))
        } else {
            fiatTotal = fiatTotal + fiatTransferFee + fiatRentFee
        }
        
        // Text label
        let tokenAmount = self.amountFrom(lamports: total)
        let fiatAmount = self.tokenToAmount(amount: self.amountFrom(lamports: total))
        let amountText = tokenAmount.tokenAmount(symbol: self.invest.asset.symbol) + " (" + fiatAmount
            .fiatAmount(currency: self.fiat) + ")"
        self.feeText = "\(L10n.excludingFeesYouLlDeposit) \(amountText)"
        
        self.detailItem.send(
            .init(
                amount: self.amountFrom(lamports: inputLamport),
                fiatAmount: self.tokenToAmount(amount: self.amountFrom(lamports: inputLamport)),
                transferFee: transferFee,
                fiatTransferFee: fiatTransferFee,
                fee: rentFee,
                fiatFee: fiatRentFee,
                total: invest.asset.symbol == fee.symbol ? tokenAmount : nil,
                fiatTotal: fiatTotal,
                symbol: self.invest.asset.symbol,
                feeSymbol: fee.symbol
            )
        )
    }

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

    private func action(lamports: UInt64) async throws {
        lock = true
        defer {
            lock = false
            finishSubject.send()
        }

        if strategy == .deposit {
            await deposit(lamports: lamports)
        } else {
            await withdraw(lamports: lamports)
        }
    }

    private func deposit(lamports: UInt64) async {
        guard
            loading == false,
            lamports > 0,
            let depositFee = depositFee
        else { return }

        notificationService
            .showInAppNotification(.done(L10n.SendingYourDepositToSolend.justWaitUntilItSDone
                    .replacingOccurrences(of: "\n", with: " ")))
        do {
            loading = true
            defer { loading = false }
            try await actionService.deposit(
                amount: lamports,
                symbol: invest.asset.symbol,
                feePayer: depositFee.feePayer
            )
        } catch {
            debugPrint(error)
            SentrySDK.capture(error: error)
            notificationService.showInAppNotification(.error(L10n.thereWasAProblemDepositingFunds))
        }
    }

    private func withdraw(lamports: UInt64) async {
        guard
            loading == false,
            lamports > 0,
            let depositFee = depositFee
        else { return }
        notificationService
            .showInAppNotification(.done(L10n.WithdrawingYourFundsFromSolend.justWaitUntilItSDone
                    .replacingOccurrences(of: "\n", with: " ")))

        let withdrawAmount = lamports == lamportFrom(amount: maxAmount()) ? UINT64_MAX : lamports

        do {
            loading = true
            defer { loading = false }
            try await actionService.withdraw(
                amount: withdrawAmount,
                symbol: invest.asset.symbol,
                feePayer: depositFee.feePayer
            )
        } catch {
            print(error)
            SentrySDK.capture(error: error)
            notificationService.showInAppNotification(.error(L10n.thereWasAProblemWithdrawingFunds))
        }
    }

    private func calculateFee(inputInLamports: UInt64, symbol: String) -> AnyPublisher<SolendFeePaying, Error> {
        Deferred {
            Future<SolendFeePaying, Error> { promise in
                Task { [weak self] in
                    do {
                        guard let self = self else { promise(.failure(DepositSolendViewModelError.unknown)); return }
                        let result = try await self.feePayingStrategy[self.strategy]!
                            .calculate(
                                amount: inputInLamports,
                                symbol: symbol,
                                mintAddress: self.invest.asset.mintAddress
                            )
                        print(result)
                        promise(.success(result))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }

    private func availableDepositModels() -> [TokenToDepositView.Model] {
        let wallets = walletRepository.getWallets()
        return market.compactMap { asset, market, _ in
            let wallet = wallets
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
    }

    // MARK: -

    func useMaxTapped() {
        focusSide = .left
        inputToken = maxAmount().toString(maximumFractionDigits: Int(maxTokenDigits))
    }

    func headerTapped() {
        if strategy == .deposit {
            let models = availableDepositModels()
            guard models.count > 1 else { return }
            tokenSelectSubject.send(models)
        } else {
            let deposits = market.filter { $2 != nil }
            guard deposits.count > 1 else { return }
            tokenSelectSubject.send(
                deposits
                    .map { asset, market, userDeposit in
                        TokenToWithdrawView.Model(
                            amount: userDeposit?.depositedAmount.double,
                            imageUrl: URL(string: asset.logo ?? ""),
                            symbol: userDeposit?.symbol ?? "",
                            fiatAmount: userDeposit?.depositedAmount.double * priceService
                                .currentPrice(for: userDeposit?.symbol ?? "")?.value,
                            apy: market?.supplyInterest.double
                        )
                    }
            )
        }
    }

    func showDetailTapped() {
        transactionDetailsSubject.send()
    }

    // MARK: -

    func showAboutSolend() {
        aboutSolendSubject.send()
    }
}

extension DepositSolendViewModel {
    enum Strategy: Equatable {
        case deposit
        case withdraw
    }

    enum DepositSolendViewModelError: Error {
        case unknown
    }
}
