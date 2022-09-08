import Combine
import Foundation
import KeyAppUI
import Resolver
import SolanaSwift
import SwiftyUserDefaults
import UIKit

class BuyViewModel: ObservableObject {
    var coordinatorIO = CoordinatorIO()

    // MARK: -

    @Published var availableMethods = [PaymentTypeItem]()
    @Published var token: Token = .nativeSolana
    @Published var fiat: Fiat = .usd
    @Published var tokenAmount: String = ""
    @Published var fiatAmount: String = "\(BuyViewModel.defaultMinAmount)"
    @Published var total: String = ""
    @Published var selectedPayment: PaymentType = .card
    @Published var isLoading = false
    @Published var areMethodsLoading = true
    @Published var isLeftFocus = false
    @Published var isRightFocus = true
    @Published var buttonTitle: String = L10n.buy
    @Published var buttonEnabled = false
    @Published var buttonIcon: UIImage? = .buyWallet
    @Published var exchangeOutput: Buy.ExchangeOutput?
    @Published var navigationSlidingPercentage: CGFloat = 1

    // MARK: -

    private var subscriptions = Set<AnyCancellable>()
    private var isGBPBankTransferEnabled = false
    private var isBankTransferEnabled = false
    private var minAmounts = [Fiat: Double]()
    private var isEditingFiat: Bool { !isLeftFocus }

    // Dependencies
    @Injected var exchangeService: BuyExchangeService
    @Injected var walletsRepository: WalletsRepository

    // Defaults
    @SwiftyUserDefault(keyPath: \.buyLastPaymentMethod, options: .cached)
    var lastMethod: PaymentType

    @SwiftyUserDefault(keyPath: \.buyMinPrices, options: .cached)
    var buyMinPrices: [String: [String: Double]]

    private static let defaultMinAmount = Double(40)
    private static let defaultMaxAmount = Double(9000)

    init() {
        fiatAmount = String(
            buyMinPrices[Fiat.usd.rawValue]?[Token.nativeSolana.symbol] ??
                BuyViewModel.defaultMinAmount
        )

        coordinatorIO.tokenSelected.compactMap { $0 }
            .assign(to: \.token, on: self)
            .store(in: &subscriptions)

        coordinatorIO.fiatSelected.compactMap { $0 }
            .assign(to: \.fiat, on: self)
            .store(in: &subscriptions)

        coordinatorIO.navigationSlidingPercentage.sink { percentage in
            self.navigationSlidingPercentage = percentage * 110 * 2
        }.store(in: &subscriptions)

        totalPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { value in
                self.total = value.total.fiatAmount(
                    maximumFractionDigits: 2,
                    currency: self.fiat
                )
                let isToken = self.isEditingFiat
                let form = BuyForm(
                    token: self.token,
                    tokenAmount: isToken ? value.amount : nil,
                    fiat: self.fiat,
                    fiatAmount: isToken ? nil : value.amount
                )
                self.exchangeOutput = value
                self.setForm(form: form)
            }).store(in: &subscriptions)

        form
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { aFiat, aToken, aAmount, _ in
                let minAmount = (self.buyMinPrices[aFiat.rawValue]?[aToken.name] ?? BuyViewModel.defaultMinAmount)
                self.buttonIcon = UIImage.buyWallet
                self.buttonTitle = L10n.buy + " " + "\(self.token.symbol)"

                if minAmount > aAmount {
                    self.buttonTitle = L10n.minimalTransactionIs(
                        minAmount.fiatAmount(
                            maximumFractionDigits: 2,
                            currency: self.fiat
                        )
                    )
                    self.buttonIcon = nil
                    self.buttonEnabled = false
                    return
                } else if aAmount > BuyViewModel.defaultMaxAmount {
                    self.buttonTitle = L10n.maximumTransactionIs(
                        BuyViewModel.defaultMaxAmount.fiatAmount(
                            maximumFractionDigits: 2,
                            currency: self.fiat
                        )
                    )
                    self.buttonIcon = nil
                    self.buttonEnabled = false
                    return
                }
                self.buttonEnabled = true
            }.store(in: &subscriptions)

        areMethodsLoading = true

        Task {
            let buyBankEnabled = available(.buyBankTransferEnabled)
            let banks = try await exchangeService.isBankTransferEnabled()
            self.isBankTransferEnabled = banks.eur && buyBankEnabled
            self.isGBPBankTransferEnabled = banks.gbp && buyBankEnabled

            await self.setPaymentMethod(self.lastMethod)

            var minPrices = [String: [String: Double]]()
            for aFiat in [Fiat.usd, Fiat.eur, Fiat.gbp] {
                for aToken in [Token.nativeSolana, Token.usdc] {
                    guard
                        let from = aFiat.buyFiatCurrency(),
                        let to = aToken.buyCryptoCurrency() else { continue }
                    if let amount = self.buyMinPrices[aFiat.rawValue]?[aToken.symbol] {
                        if minPrices[aFiat.rawValue] == nil {
                            minPrices[aFiat.rawValue] = [:]
                        }
                        minPrices[aFiat.rawValue]?[aToken.symbol] = amount
                    } else {
                        let result = try? await self.exchangeService.getMinAmounts(from, to)
                        guard result?.0 ?? 0 > 0 else { continue }
                        if minPrices[aFiat.rawValue] == nil {
                            minPrices[aFiat.rawValue] = [:]
                        }
                        minPrices[aFiat.rawValue]?[aToken.symbol] = result?.0 ?? BuyViewModel.defaultMinAmount
                    }
                }
            }
            self.buyMinPrices = minPrices

            DispatchQueue.main.async {
                // Set last used method first
                self.availableMethods = self.availablePaymentTypes()
                    .filter { $0 != self.lastMethod }
                    .map { $0.paymentItem() }
                if self.availablePaymentTypes().contains(self.lastMethod) {
                    self.availableMethods
                        .insert(self.lastMethod.paymentItem(), at: 0)
                }
                self.areMethodsLoading = false
            }
        }
    }

    @MainActor func didSelectPayment(_ payment: PaymentTypeItem) {
        selectedPayment = payment.type
        setPaymentMethod(payment.type)
    }

    // MARK: -

    @MainActor
    private func setPaymentMethod(_ payment: PaymentType) {
        selectedPayment = payment
        lastMethod = payment
        // If selected payment doesnt have current currency
        // - changing to the fist one from allowed
        if !availableFiat(payment: selectedPayment).contains(fiat) {
            fiat = availableFiat(payment: selectedPayment).first ?? .usd
        }
    }

    func totalTapped() async throws {
        guard let exchangeOutput = exchangeOutput else { return }
        do {
            guard
                let fiat = fiat.buyFiatCurrency(),
                let token = token.buyCryptoCurrency()
            else { return }
            let exchangeRate = try await exchangeService.getExchangeRate(from: fiat, to: token)
            coordinatorIO.showDetail.send((exchangeOutput, exchangeRate: exchangeRate.amount, fiat: self.fiat))
        }
    }

    func tokenSelectTapped() {
        let tokens = [Token.nativeSolana, Token.usdc]
        coordinatorIO.showTokenSelect.send(tokens)
    }

    func fiatSelectTapped() {
        coordinatorIO.showFiatSelect.send(availableFiat(payment: selectedPayment))
    }

    func buyButtonTapped() {
        guard
            let from = fiat.buyFiatCurrency(),
            let to = token.buyCryptoCurrency(),
            let amount = Double(fiatAmount),
            let url = try? getExchangeURL(
                from: from,
                to: to,
                amount: amount
            ) else { return }
        coordinatorIO.buy.send(url)
    }

    // MARK: -

    var form: AnyPublisher<(Buy.FiatCurrency, Buy.CryptoCurrency, Double, Double), Never> {
        Publishers.CombineLatest4(
            $fiat.removeDuplicates().compactMap { $0.buyFiatCurrency() },
            $token.removeDuplicates().compactMap { $0.buyCryptoCurrency() },
            $fiatAmount.map { Double($0) ?? 0 }.removeDuplicates(),
            $tokenAmount.map { Double($0) ?? 0 }.removeDuplicates()
        ).eraseToAnyPublisher()
    }

    var totalPublisher: AnyPublisher<Buy.ExchangeOutput, Never> {
        Publishers.CombineLatest(
            form,
            $selectedPayment.removeDuplicates()
        )
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .map { form, paymentType -> (BuyCurrencyType, BuyCurrencyType, Double, PaymentType) in
                let (fiat, token, fAmount, tAmount) = form
                let from: BuyCurrencyType
                let to: BuyCurrencyType
                let amount: Double
                if self.isEditingFiat {
                    from = fiat
                    to = token
                    amount = fAmount
                } else {
                    from = token
                    to = fiat
                    amount = tAmount
                }
                return (from, to, amount, paymentType)
            }.removeDuplicates(by: { aLeft, aRight in
                // Checking first param for equality
                if
                    // 1 step if it's fiat
                    let lFiat = (aLeft.0 as? Buy.FiatCurrency),
                    let rFiat = aRight.0 as? Buy.FiatCurrency
                {
                    guard lFiat == rFiat else { return false }
                } else if
                    // 2 step if it's crypto
                    let lCrypto = aLeft.0 as? Buy.CryptoCurrency,
                    let rCrypto = aRight.0 as? Buy.CryptoCurrency
                {
                    guard lCrypto == rCrypto else { return false }
                } else {
                    return false
                }
                // The same with second param
                if
                    let lFiat = (aLeft.1 as? Buy.FiatCurrency),
                    let rFiat = aRight.1 as? Buy.FiatCurrency
                {
                    guard lFiat == rFiat else { return false }
                } else if
                    let lCrypto = aLeft.1 as? Buy.CryptoCurrency,
                    let rCrypto = aRight.1 as? Buy.CryptoCurrency
                {
                    guard lCrypto == rCrypto else { return false }
                } else {
                    return false
                }
                // and the rest
                return aLeft.2 == aRight.2 && aLeft.3 == aRight.3
            }).handleEvents(receiveOutput: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.isLoading = true
                }
            }).map { from, to, amount, paymentType -> AnyPublisher<Buy.ExchangeOutput, Never> in
                self.exchange(
                    from: from,
                    to: to,
                    amount: amount,
                    paymentType: paymentType
                )
            }
            .replaceError(with: nil)
            .handleEvents(receiveOutput: { _ in
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            })
            .replaceError(with: nil)
            .handleEvents(receiveOutput: { _ in
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            })
            .compactMap { $0 }
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            // Getting only last request
            .switchToLatest()
            .eraseToAnyPublisher()
    }

    func exchange(
        from: BuyCurrencyType,
        to: BuyCurrencyType,
        amount: Double,
        paymentType: PaymentType
    ) -> AnyPublisher<Buy.ExchangeOutput, Never> {
        Future { promise in
            Task { [weak self] in
                guard let self = self else { return }
                try Task.checkCancellation()
                let result = try await self.exchangeService.convert(
                    input: .init(
                        amount: amount,
                        currency: from
                    ),
                    to: to,
                    paymentType: paymentType
                )
                try Task.checkCancellation()
                promise(.success(result))
            }
        }.eraseToAnyPublisher()
    }

    func setForm(form: BuyForm) {
        DispatchQueue.main.async {
            self.token = form.token
            if let tokenAmount = form.tokenAmount {
                self.tokenAmount = tokenAmount.toString()
            }
            self.fiat = form.fiat
            if let fiatAmount = form.fiatAmount {
                self.fiatAmount = fiatAmount.toString()
            }
        }
    }

    func getExchangeURL(from: BuyCurrencyType, to: BuyCurrencyType, amount: Double) throws -> URL {
        let factory: BuyProcessingFactory = Resolver.resolve()
        let provider = try factory.create(
            walletRepository: walletsRepository,
            fromCurrency: from,
            amount: amount,
            toCurrency: to,
            paymentMethod: selectedPayment.rawValue
        )
        return URL(string: provider.getUrl())!
    }

    func availableFiat(payment: PaymentType) -> [Fiat] {
        switch payment {
        case .card:
            return [.eur, .gbp, .usd]
        case .bank:
            return isGBPBankTransferEnabled ? [.eur, .gbp] : [.eur]
        }
    }

    func availablePaymentTypes() -> [PaymentType] {
        PaymentType.allCases.filter {
            if case .bank = $0 {
                return self.isBankTransferEnabled || self.isGBPBankTransferEnabled
            }
            return true
        }
    }

    // MARK: -

    struct BuyForm: Equatable {
        var token: Token
        var tokenAmount: Double?
        var fiat: Fiat
        var fiatAmount: Double?
    }
}

extension BuyViewModel {
    struct CoordinatorIO {
        // Input
        var showDetail = PassthroughSubject<(Buy.ExchangeOutput, exchangeRate: Double, fiat: Fiat), Never>()
        var showTokenSelect = PassthroughSubject<[Token], Never>()
        var showFiatSelect = PassthroughSubject<[Fiat], Never>()
        var navigationSlidingPercentage = PassthroughSubject<CGFloat, Never>()
        // Output
        var tokenSelected = CurrentValueSubject<Token?, Never>(nil)
        var fiatSelected = CurrentValueSubject<Fiat?, Never>(nil)
        var buy = PassthroughSubject<URL, Never>()
    }

    struct TotalResult {
        var total: String
        var totalCurrency: Fiat
        var token: Token
        var fiat: Fiat
        var tokenAmount: String
        var fiatAmmount: String
    }
}

extension BuyViewModel {
    struct PaymentTypeItem: Equatable {
        var type: PaymentType
        var fee: String
        var duration: String
        var name: String
        var icon: UIImage
    }
}

enum PaymentType: String, DefaultsSerializable, CaseIterable {
    case card
    case bank
}

extension PaymentType {
    func paymentItem() -> BuyViewModel.PaymentTypeItem {
        switch self {
        case .bank:
            return .init(
                type: self,
                fee: "1%",
                duration: "~17 hours",
                name: "Bank transfer",
                icon: UIImage.buyBank
            )
        case .card:
            return .init(
                type: self,
                fee: "4.5%",
                duration: "instant",
                name: "Card",
                icon: UIImage.buyCard
            )
        }
    }
}
