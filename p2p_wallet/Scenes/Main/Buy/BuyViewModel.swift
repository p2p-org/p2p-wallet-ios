import Combine
import Foundation
import KeyAppUI
import Resolver
import SolanaSwift
import SwiftyUserDefaults

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

    init() {
        coordinatorIO.tokenSelected.sink { token in
            self.token = token
        }.store(in: &subscriptions)

        coordinatorIO.fiatSelected.sink { fiat in
            self.fiat = fiat
        }.store(in: &subscriptions)

        totalPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { value in
                self.total = value.total.fiatAmount(maximumFractionDigits: 2, currency: self.fiat)
                let isToken = self.isEditingFiat
                let form = BuyForm(
                    token: self.token,
                    tokenAmount: isToken ? value.amount : nil,
                    fiat: self.fiat,
                    fiatAmount: isToken ? nil : value.amount
                )
                self.setForm(form: form)
            }).store(in: &subscriptions)

        form.map { aFiat, aToken, aAmount, _ -> String in
            let minAmount = (self.buyMinPrices[aFiat.rawValue]?[aToken.name] ?? BuyViewModel.defaultMinAmount)
            if minAmount > aAmount {
                return L10n.minimalTransactionIs(
                    minAmount.fiatAmount(
                        maximumFractionDigits: 2,
                        currency: self.fiat
                    )
                )
            }
            return L10n.buy
        }
        .assign(to: \.buttonTitle, on: self)
        .store(in: &subscriptions)

        areMethodsLoading = true

        Task {
            let banks = try await exchangeService.isBankTransferEnabled()
            self.isBankTransferEnabled = banks.eur
            self.isGBPBankTransferEnabled = banks.gbp

            await self.setPaymentMethod(self.lastMethod)

            var minPrices = [String: [String: Double]]()
            for aFiat in [Fiat.usd, Fiat.eur, Fiat.gbp] {
                for aToken in [Token.nativeSolana, Token.usdc] {
                    guard
                        let from = aFiat.buyFiatCurrency(),
                        let to = aToken.buyCryptoCurrency() else { continue }
                    if let amount = self.buyMinPrices[aFiat.rawValue]?[aToken.name] {
                        minPrices[aFiat.rawValue] = [aToken.name: amount]
                    } else {
                        let result = try? await self.exchangeService.getMinAmounts(from, to)
                        guard result?.0 > 0 else { continue }
                        minPrices[aFiat.rawValue] = [aToken.name: result?.0 ?? BuyViewModel.defaultMinAmount]
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

    // TODO: rename
    func didTapTotal() {
        coordinatorIO.showDetail.send()
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
            $fiat.removeDuplicates().map { $0.buyFiatCurrency()! },
            $token.removeDuplicates().map { $0.buyCryptoCurrency()! },
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
                guard lFiat == rFiat else { return true }
            } else if
                // 2 step if it's crypto
                let lCrypto = aLeft.0 as? Buy.CryptoCurrency,
                let rCrypto = aRight.0 as? Buy.CryptoCurrency
            {
                guard lCrypto == rCrypto else { return true }
            } else {
                return false
            }
            // The same with second param
            if
                let lFiat = (aLeft.1 as? Buy.FiatCurrency),
                let rFiat = aRight.1 as? Buy.FiatCurrency
            {
                guard lFiat == rFiat else { return true }
            } else if
                let lCrypto = aLeft.1 as? Buy.CryptoCurrency,
                let rCrypto = aRight.1 as? Buy.CryptoCurrency
            {
                guard lCrypto == rCrypto else { return true }
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
        .replaceError(with: nil).compactMap { $0 }
        .subscribe(on: DispatchQueue.global())
        .receive(on: DispatchQueue.main)
        // Getting only last request
        .switchToLatest()
        .handleEvents(receiveOutput: { _ in
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }).eraseToAnyPublisher()
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
//                do {
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
//                } catch let error {
//                    promise(.failure(error))
//                }
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
            if isGBPBankTransferEnabled {
                return [.eur, .gbp]
            }
            return [.eur]
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
        var showDetail = PassthroughSubject<Void, Never>()
        var showTokenSelect = PassthroughSubject<[Token], Never>()
        var showFiatSelect = PassthroughSubject<[Fiat], Never>()
        // Output
        var tokenSelected = PassthroughSubject<Token, Never>()
        var fiatSelected = PassthroughSubject<Fiat, Never>()
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

//    struct Model {
//        let solPrice: Double
//        let solPurchaseCost: Double
//        let processingFee: Double
//        let networkFee: Double
//        let total: Double
//        let currency: Fiat
//
//        fileprivate func convertedAmount(_ amount: Double) -> String {
//            amount.fiatAmount(maximumFractionDigits: 2, currency: currency)
//        }
//    }
}

extension BuyViewModel {
    struct PaymentTypeItem: Equatable {
        var type: PaymentType
        var fee: String
        // TODO: rename to 'duration'
        var time: String
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
                time: "~17 hours",
                name: "Bank transfer",
                icon: UIImage.buyBank
            )
        case .card:
            return .init(
                type: self,
                fee: "4%",
                time: "instant",
                name: "Card",
                icon: UIImage.buyCard
            )
        }
    }
}

protocol BuyExchangeService {
    func getMinAmount(currency: Buy.Currency) async throws -> Double
    func getMinAmounts(_ currency1: Buy.Currency, _ currency2: Buy.Currency) async throws -> (Double, Double)
    func convert(input: Buy.ExchangeInput, to currency: Buy.Currency, paymentType: PaymentType) async throws -> Buy
        .ExchangeOutput
    func getExchangeRate(from fiatCurrency: Buy.FiatCurrency, to cryptoCurrency: Buy.CryptoCurrency) async throws -> Buy
        .ExchangeRate
    func isBankTransferEnabled() async throws -> (gbp: Bool, eur: Bool)
}

struct MoonpayExchange: BuyExchangeService {
    let provider: Moonpay.Provider

    init(provider: Moonpay.Provider) { self.provider = provider }

    func convert(
        input: Buy.ExchangeInput,
        to currency: Buy.Currency,
        paymentType: PaymentType
    ) async throws -> Buy.ExchangeOutput {
        let currencies = [input.currency, currency]
        let base = currencies.first { $0 is Buy.FiatCurrency }
        let quote = currencies.first { $0 is Buy.CryptoCurrency }

        guard
            let base = base as? MoonpayCodeMapping,
            let quote = quote as? MoonpayCodeMapping
        else {
//            throw Exception.invalidInput
            fatalError()
        }

        let baseAmount = input.currency is Buy.Currency ? input.amount : nil
        let quoteAmount = input.currency is Buy.CryptoCurrency ? input.amount : nil

        do {
            let buyQuote = try await provider
                .getBuyQuote(
                    baseCurrencyCode: base.moonpayCode,
                    quoteCurrencyCode: quote.moonpayCode,
                    baseCurrencyAmount: baseAmount,
                    quoteCurrencyAmount: quoteAmount,
                    paymentMethod: PaymentType.card == paymentType ? .creditDebitCard : .sepaBankTransfer
                )

            return Buy.ExchangeOutput(
                amount: currency is Buy.CryptoCurrency ? buyQuote.quoteCurrencyAmount : buyQuote.totalAmount,
                currency: currency,
                processingFee: buyQuote.feeAmount,
                networkFee: buyQuote.networkFeeAmount,
                purchaseCost: buyQuote.baseCurrencyAmount,
                total: buyQuote.totalAmount
            )
        } catch {
            throw error
        }
    }

    func getExchangeRate(
        from fiatCurrency: Buy.FiatCurrency,
        to cryptoCurrency: Buy.CryptoCurrency
    ) async throws -> Buy.ExchangeRate {
        let exchangeRate = try await provider
            .getPrice(for: cryptoCurrency.moonpayCode, as: fiatCurrency.moonpayCode.uppercased())

        return .init(amount: exchangeRate, cryptoCurrency: cryptoCurrency, fiatCurrency: fiatCurrency)
    }

    private func _getMinAmount(currencies: Moonpay.Currencies, for currency: BuyCurrencyType) -> Double {
        guard let currency = currency as? MoonpayCodeMapping else { return 0.0 }
        return currencies.first { e in e.code == currency.moonpayCode }?.minBuyAmount ?? 0.0
    }

    func getMinAmount(currency: Buy.Currency) async throws -> Double {
        let currencies = try await provider
            .getAllSupportedCurrencies()
        return _getMinAmount(currencies: currencies, for: currency)
    }

    func getMinAmounts(_ currency1: Buy.Currency, _ currency2: Buy.Currency) async throws -> (Double, Double) {
        let currencies = try await provider.getAllSupportedCurrencies()
        return (
            _getMinAmount(currencies: currencies, for: currency1),
            _getMinAmount(currencies: currencies, for: currency2)
        )
    }

    /// Weather banks are available for this provider
    func isBankTransferEnabled() async throws -> (gbp: Bool, eur: Bool) {
        let banks = try await provider.bankTransferAvailability()
        return (gbp: banks.gbp, eur: banks.eur)
    }
}

extension Buy.FiatCurrency {
    func fiat(_ fiatCurrency: Buy.FiatCurrency) -> Fiat? {
        Fiat(rawValue: fiatCurrency.rawValue)
    }
}

extension Fiat {
    func fiatCurrency(_ fiat: Fiat) -> Buy.FiatCurrency? {
        Buy.FiatCurrency(rawValue: fiat.rawValue)
    }

    func buyFiatCurrency() -> Buy.FiatCurrency? {
        Buy.FiatCurrency(rawValue: rawValue)
    }
}

extension Token {
    func buyCryptoCurrency() -> Buy.CryptoCurrency? {
        Buy.CryptoCurrency(rawValue: symbol.lowercased())
    }
}
