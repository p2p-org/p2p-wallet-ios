import BankTransfer
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import KeyAppUI
import Reachability
import Resolver
import SolanaSwift
import UIKit

final class WithdrawCalculatorViewModel: BaseViewModel, ObservableObject {
    // MARK: - Dependencies

    @Injected private var bankTransferService: AnyBankTransferService<StrigaBankTransferUserDataRepository>
    @Injected private var notificationService: NotificationService
    @Injected private var reachability: Reachability
    @Injected private var solanaAccountsService: SolanaAccountsService

    // MARK: - Properties

    let actionPressed = PassthroughSubject<Void, Never>()
    let allButtonPressed = PassthroughSubject<Void, Never>()
    let openBankTransfer = PassthroughSubject<Void, Never>()
    let openWithdraw = PassthroughSubject<StrigaWithdrawalInfo, Never>()
    let proceedBankTransfer = PassthroughSubject<Void, Never>()

    @Published var actionData = WithdrawCalculatorAction.zero
    @Published var isLoading = false

    @Published var arePricesLoading = false
    @Published var exchangeRatesInfo = ""

    @Published var fromAmount: Double?
    @Published var toAmount: Double?

    @Published var fromAmountTextColor: UIColor = Asset.Colors.rose.color

    @Published var isFromFirstResponder = false
    @Published var isToFirstResponder = false
    @Published var isFromEnabled = true
    @Published var isToEnabled = false

    @Published var fromBalance: Double?
    @Published var fromBalanceText = ""

    @Published var fromTokenSymbol = Token.usdc.symbol.uppercased()
    @Published var toTokenSymbol = Constants.EUR.symbol

    @Published var fromDecimalLength = Int(Token.usdc.decimals)
    @Published var toDecimalLength = Constants.EUR.decimals

    private var exchangeRatesFailCount = 0
    private var exchangeRatesTimer: Timer?
    @Published private var exchangeRates: StrigaExchangeRates?

    override init() {
        super.init()
        loadRates()
        bindProperties()
        bindReachibility()
        bindAccounts()
    }

    deinit {
        exchangeRatesTimer?.invalidate()
    }
}

private extension WithdrawCalculatorViewModel {
    func bindProperties() {
        Publishers.CombineLatest(
            $fromAmount.eraseToAnyPublisher(),
            $exchangeRates.eraseToAnyPublisher()
        )
        .sink { [weak self] amount, rates in
            guard let self, let rates else { return }
            var newToAmount: Double?
            if let amount {
                newToAmount = amount * Double(rates.sell)
            }
            guard self.toAmount != newToAmount else { return }
            self.toAmount = newToAmount
        }
        .store(in: &subscriptions)

        Publishers.CombineLatest(
            $toAmount.eraseToAnyPublisher(),
            $exchangeRates.eraseToAnyPublisher()
        )
        .sink { [weak self] amount, rates in
            guard let self, let rates else { return }
            var newFromAmount: Double?
            if let amount {
                newFromAmount = amount / Double(rates.sell)
            }
            guard self.fromAmount != newFromAmount else { return }
            self.fromAmount = newFromAmount
        }
        .store(in: &subscriptions)

        // Validation
        Publishers.CombineLatest3(
            $exchangeRates.eraseToAnyPublisher(),
            $fromAmount.eraseToAnyPublisher(),
            $toAmount.eraseToAnyPublisher()
        )
        .sink { [weak self] _, fromAmount, toAmount in
            guard let self else { return }
            switch (fromAmount, toAmount) {
            case (nil, _), (Double.zero, _):
                self.actionData = .zero
                self.fromAmountTextColor = Asset.Colors.night.color
            case (fromAmount, toAmount) where fromAmount > self.fromBalance:
                self.actionData = WithdrawCalculatorAction(isEnabled: false, title: L10n.notEnoughMoney)
                self.fromAmountTextColor = Asset.Colors.rose.color
            case (fromAmount, toAmount) where toAmount < Constants.EUR.min:
                actionData = WithdrawCalculatorAction(
                    isEnabled: false,
                    title: L10n.asMinimalAmountForTransfer(Constants.EUR.min.formattedFiat(currency: .eur))
                )
                self.fromAmountTextColor = Asset.Colors.rose.color
            case (fromAmount, toAmount) where toAmount > Constants.EUR.max:
                actionData = WithdrawCalculatorAction(
                    isEnabled: false,
                    title: L10n.onlyPerOneTransfer(Constants.EUR.max.formattedFiat(currency: .eur))
                )
                self.fromAmountTextColor = Asset.Colors.rose.color
            default:
                actionData = WithdrawCalculatorAction(isEnabled: true, title: L10n.next.uppercaseFirst)
                self.fromAmountTextColor = Asset.Colors.night.color
            }
        }
        .store(in: &subscriptions)

        $fromBalance
            .receive(on: RunLoop.main)
            .map { [weak self] balance in
                guard let self, let balance else { return "" }
                return balance.toString(maximumFractionDigits: self.fromDecimalLength)
            }
            .assignWeak(to: \.fromBalanceText, on: self)
            .store(in: &subscriptions)

        allButtonPressed
            .map { [weak self] in self?.fromBalance }
            .assignWeak(to: \.fromAmount, on: self)
            .store(in: &subscriptions)

        $exchangeRates
            .receive(on: RunLoop.main)
            .map { [weak self] rates in
                guard let self, let rates else { return "" }
                return "\(1) \(self.toTokenSymbol) ≈ \(rates.sell) \(self.fromTokenSymbol)"
            }
            .assignWeak(to: \.exchangeRatesInfo, on: self)
            .store(in: &subscriptions)

        actionPressed
            .withLatestFrom(bankTransferService.value.state)
            .sinkAsync { [weak self] state in
                guard let self else { return }
                self.openWithdraw.send(StrigaWithdrawalInfo(IBAN: "4560001 5001 5800 1234 0000 11", BIC: "TRONLOLIPOPXXX", receiver: "Lord Voldemort"))
//                if state.value.kycStatus != .approved {
//                    self.openBankTransfer.send()
//                } else if state.value.isIBANNotReady {
//                    self.isLoading = true
//                    await self.bankTransferService.value.reload()
//                    self.proceedBankTransfer.send()
//                }
                // todo add get statement request
            }
            .store(in: &subscriptions)

        proceedBankTransfer
            .withLatestFrom(bankTransferService.value.state)
            .sinkAsync { [weak self] state in
                guard let self else { return }
                if state.value.isIBANNotReady {
                    self.notificationService.showDefaultErrorNotification()
                } else {
                    // iban and bic
                    // todo add get statement request
                }
            }
            .store(in: &subscriptions)

        $arePricesLoading
            .filter { $0 }
            .map { _ in return WithdrawCalculatorAction(isEnabled: false, title: L10n.gettingRates) }
            .receive(on: RunLoop.main)
            .assignWeak(to: \.actionData, on: self)
            .store(in: &subscriptions)
    }

    func bindAccounts() {
        solanaAccountsService.statePublisher
            .map { $0.value.first(where: { $0.data.mintAddress == Token.usdc.address })?.cryptoAmount.amount }
            .map { value in
                if let value {
                    return Double(exactly: value)
                }
                return nil
            }
            .assignWeak(to: \.fromBalance, on: self)
            .store(in: &subscriptions)
    }

    func bindReachibility() {
        reachability
            .isReachable
            .withPrevious()
            .filter { prev, current in
                prev == false && current == true // Only if value changed from false
            }
            .sink { [weak self] _ in self?.loadRates() }
            .store(in: &subscriptions)

        reachability
            .isDisconnected
            .sink { [weak self] in
                self?.cancelUpdate()
                self?.notificationService.showConnectionErrorNotification()
            }
            .store(in: &subscriptions)
    }

    func loadRates() {
        arePricesLoading = true
        changeEditing(isEnabled: false)
        Task {
            do {
                let response = try await bankTransferService.value.repository.exchangeRates(
                    from: fromTokenSymbol,
                    to: toTokenSymbol
                )
                exchangeRates = response
                arePricesLoading = false
                exchangeRatesFailCount = 0
                scheduleRatesUpdate()
                changeEditing(isEnabled: true)
            } catch let error as NSError where error.isNetworkConnectionError {
                notificationService.showConnectionErrorNotification()
                commonErrorHandling()
            } catch {
                commonErrorHandling()
                exchangeRatesFailCount = exchangeRatesFailCount + 1
                if exchangeRatesFailCount < Constants.exchangeRatesMaxFailNumber {
                    loadRates() // Call request again
                } else {
                    notificationService.showDefaultErrorNotification()
                }
            }
        }
    }

    func commonErrorHandling() {
        arePricesLoading = false
        actionData = WithdrawCalculatorAction.failure
        exchangeRates = nil
    }

    func changeEditing(isEnabled: Bool) {
        isFromEnabled = isEnabled
        isToEnabled = isEnabled
    }

    // Timer for exchangeRates request
    func scheduleRatesUpdate() {
        cancelUpdate()
        exchangeRatesTimer = .scheduledTimer(
            withTimeInterval: Constants.exchangeRatesInterval,
            repeats: true
        ) { [weak self] _ in
            self?.loadRates()
        }
    }

    func cancelUpdate() {
        exchangeRatesTimer?.invalidate()
    }
}

private enum Constants {
    static let exchangeRatesMaxFailNumber = 3
    static let exchangeRatesInterval = TimeInterval(60)

    enum EUR {
        static let decimals = 2
        static let symbol = "EUR"
        static let min: Double = 1
        static let max: Double = 15000
    }
}
