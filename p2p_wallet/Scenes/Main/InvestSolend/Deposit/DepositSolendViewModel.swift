import Combine
import FeeRelayerSwift
import Foundation
import Resolver
import SolanaSwift
import Solend

@MainActor
class DepositSolendViewModel: ObservableObject {
    private let dataService: SolendDataService
    private let actionService: SolendActionService

    @Injected private var notificationService: NotificationService
    @Injected private var priceService: PricesServiceType
    @Injected private var walletRepository: WalletsRepository

    var subscriptions = Set<AnyCancellable>()

    @Published var focusSide: BuyInputOutputActiveSide = .left
    /// Is loading fees
    @Published var loading: Bool = false
    @Published var inputToken: String = "0"
    @Published var inputFiat: String = "0"
    @Published var fiat: Fiat = Defaults.fiat
    @Published var invest: Invest
    @Published var depositFee: SolendDepositFee?
    @Published var inputLamport: UInt64 = 0
    @Published var isButtonEnabled: Bool = false
    @Published var buttonText: String = "Enter the amount"
    @Published var hasError = false
    @Published var feeText = L10n.withdrawYourFundsWithAllRewardsAtAnyTime
    @Published var maxText = "Use all"
    @Published var isUsingMax = false
    /// Deposit slider position
    @Published var isDepositOn = false
    /// Balance for selected Token
    private var currentWallet: Wallet? {
        walletRepository.getWallets().filter { $0.token.address == self.invest.asset.mintAddress }.first
    }

    /// Rate for selected pair Token -> Fiat
    private var tokenFiatPrice: Double?

    init(initialAsset: SolendConfigAsset, mocked: Bool = false) throws {
        dataService = mocked ? SolendDataServiceMock() : Resolver.resolve(SolendDataService.self)
        actionService = mocked ? SolendActionServiceMock() : Resolver.resolve(SolendActionService.self)
        invest = (asset: initialAsset, market: nil, userDeposit: nil)

        tokenFiatPrice = priceService.currentPrice(for: invest.asset.symbol)?.value
        maxText = "Use all \(currentWallet?.amount?.toString(maximumFractionDigits: 9) ?? "0") \(invest.asset.symbol)"

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
            }
            .store(in: &subscriptions)
        bind()
    }

    private func bind() {
        $inputToken
            .map { self.currentWallet?.amount ?? 0 >= Double($0) }
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
                self.loading = true
                if self.focusSide == .left { // editing token
                    if self.tokenFiatPrice > 0, self.inputInLamport > 0 {
                        self.inputFiat = ((self.tokenFiatPrice ?? 0) * tokenAmount).toString(maximumFractionDigits: 2)
                    } else {
                        self.inputFiat = "0"
                    }
                } else {
                    if self.tokenFiatPrice > 0 {
                        self.inputToken = (fiatAmount / self.tokenFiatPrice).toString(maximumFractionDigits: 9)
                    } else {
                        self.inputToken = "0"
                    }
                }
                self.inputLamport = self.inputInLamport
                self.hasError = false
                self.isUsingMax = false
                if self.currentWallet?.amount ?? 0 < self.inputLamport
                    .convertToBalance(decimals: self.invest.asset.decimals)
                {
                    let maxAmount = (self.currentWallet?.amount ?? 0)
                    self
                        .buttonText =
                        "MAX amount is \(maxAmount.toString(maximumFractionDigits: 9)) \(self.invest.asset.symbol)"
                    self.feeText = "Enter the correct amount to continue"
                    self.hasError = true
                    self.loading = false
                } else {
                    self.feeText = L10n.withdrawYourFundsWithAllRewardsAtAnyTime
                }
                if self.currentWallet?.amount ?? 0 == self.inputLamport
                    .convertToBalance(decimals: self.invest.asset.decimals)
                {
                    self.isUsingMax = true
                }
            })
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .map { val -> AnyPublisher<SolendDepositFee?, Never> in
                guard self.inputInLamport > 0, !self.hasError else { return Just(nil).eraseToAnyPublisher() }
                return self.calculateFee(
                    inputInLamports: self.lamportFrom(amount: Double(val.0)),
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
                if let fee {
                    let totalAmountLamports = self.inputInLamport.subtractingReportingOverflow(fee.fee).partialValue
                    let fiatAmount = self.amountFrom(lamports: totalAmountLamports) * (self.tokenFiatPrice ?? 0)
                    let amountText =
                        "\(self.amountFrom(lamports: totalAmountLamports).toString(maximumFractionDigits: 9)) \(self.invest.asset.symbol) (\(self.fiat.symbol) \(fiatAmount.toString(maximumFractionDigits: 2)))"
                    self.feeText = "Excluding fees you will deposit \(amountText)"
                }
            })
            .store(in: &subscriptions)

        $isDepositOn.filter { $0 }
            .sink { [weak self] _ in
                Task {
                    do {
                        try await self?.deposit()
                    } catch {
                        debugPrint(error)
                    }
                }
            }.store(in: &subscriptions)
    }

    var inputInLamport: UInt64 {
        guard let amount = Double(inputToken) else { return 0 }
        return min(UInt64.max, UInt64(amount * pow(10, Double(invest.asset.decimals))))
    }

    func lamportFrom(amount: Double) -> UInt64 {
        UInt64(amount * pow(10, Double(invest.asset.decimals)))
    }

    func amountFrom(lamports: UInt64) -> Double {
        Double(lamports) / pow(10, Double(invest.asset.decimals))
    }

    func deposit() async throws {
        guard loading == false, inputInLamport > 0 else { return }
        do {
            loading = true
            defer { loading = false }

            try await actionService.deposit(amount: inputInLamport, symbol: invest.asset.symbol)
        } catch {
            notificationService.showInAppNotification(.error(error.localizedDescription))
        }
    }

    func calculateFee(inputInLamports: UInt64, symbol: String) -> AnyPublisher<SolendDepositFee, Error> {
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
        inputToken = currentWallet?.amount?.toString(maximumFractionDigits: 9) ?? "0"
        inputFiat = ((tokenFiatPrice ?? 0) * currentWallet?.amount).toString(maximumFractionDigits: 2)
        inputLamport = inputInLamport
    }
}
