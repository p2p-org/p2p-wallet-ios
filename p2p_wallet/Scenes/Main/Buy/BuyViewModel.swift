import Combine
import Foundation
import KeyAppUI
import SolanaSwift
import SwiftyUserDefaults
import Resolver

class BuyViewModel: ObservableObject {
    var coordinatorIO = CoordinatorIO()
    private var subscriptions = Set<AnyCancellable>()

    @Published var availableMethods = [PaymentTypeItem]()
    @Published var token: Token = .nativeSolana
    @Published var fiat: Fiat = .usd
    @Published var tokenAmount: String = ""
    @Published var fiatAmount: String = "40"
    @Published var total: String = ""
    @Published var selectedPayment: PaymentType?
    @Published var isLoading = false

    private var toggle: Bool {
        !isLeftFocus
    }

    @Published var isLeftFocus = false
    @Published var isRightFocus = true

    // Dependencies
    @Injected var exchangeService: BuyExchangeService

    @SwiftyUserDefault(keyPath: \.buyLastPaymentMethod, options: .cached) var lastMethod: PaymentType

    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    init() {
        selectedPayment = lastMethod
        // Set last used method first
        availableMethods = PaymentType.allCases.filter { $0 != lastMethod }.map { $0.paymentItem() }
        availableMethods.insert(lastMethod.paymentItem(), at: 0)

        coordinatorIO.tokenSelected.sink { token in
            self.token = token
        }.store(in: &subscriptions)

        coordinatorIO.fiatSelected.sink { fiat in
            self.fiat = fiat
        }.store(in: &subscriptions)

        totalPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { value in
                self.total = value.total.toString()
                let isToken = self.toggle //(value.currency as? Buy.CryptoCurrency) != nil
                let form = BuyForm(
                    token: self.token,
                    tokenAmount: isToken ? value.amount : nil,
                    fiat: self.fiat,
                    fiatAmount: isToken ? nil : value.amount
                )
                self.setForm(form: form)
            }).store(in: &subscriptions)
    }

    func didSelectPayment(_ payment: PaymentTypeItem) {
        lastMethod = payment.type
        selectedPayment = payment.type
    }

    // TODO: rename
    func didTapTotal() {
        coordinatorIO.showDetail.send()
    }

    func tokenSelectTapped() {
        coordinatorIO.showTokenSelect.send()
    }

    func fiatSelectTapped() {
        coordinatorIO.showFiatSelect.send()
    }

    // MARK: -

    var totalPublisher: AnyPublisher<Buy.ExchangeOutput, Never> {
        Publishers.CombineLatest4(
            $fiat.map { $0.buyFiatCurrency()! }.removeDuplicates(),
            $token.map { $0.buyCryptoCurrency()! }.removeDuplicates(),
            $fiatAmount.map { Double($0) ?? 0 }.removeDuplicates(),
            $tokenAmount.map { Double($0) ?? 0 }.removeDuplicates()
        )
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .map({ fiat, token, fAmount, tAmount -> (BuyCurrencyType, BuyCurrencyType, Double) in
                let from: BuyCurrencyType
                let to: BuyCurrencyType
                let amount: Double
                if self.toggle {
                    from = fiat
                    to = token
                    amount = fAmount
                } else {
                    from = token
                    to = fiat
                    amount = tAmount
                }
                return (from, to, amount)
            })
            .handleEvents(receiveOutput: { _ in
                self.isLoading = true
            })
            .map { from, to, amount -> AnyPublisher<Buy.ExchangeOutput, Never> in
                self.exchange(from: from, to: to, amount: amount)
            }
            .replaceError(with: nil)
            .compactMap { $0 }
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

    func exchange(from: BuyCurrencyType, to: BuyCurrencyType, amount: Double) -> AnyPublisher<Buy.ExchangeOutput, Never> {
        Future { promise in
            Task { [weak self]  in
                try Task.checkCancellation()
                let result = try await self!.exchangeService.convert(
                    input: .init(
                        amount: amount,
                        currency: from
                    ),
                    to: to
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
        var showTokenSelect = PassthroughSubject<Void, Never>()
        var showFiatSelect = PassthroughSubject<Void, Never>()
        // Output
        var tokenSelected = PassthroughSubject<Token, Never>()
        var fiatSelected = PassthroughSubject<Fiat, Never>()
    }

    struct TotalResult {
        var total: String
        var totalCurrency: Fiat
        var token: Token
        var fiat: Fiat
        var tokenAmount: String
        var fiatAmmount: String
    }
//
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
    enum PaymentType: String, DefaultsSerializable, CaseIterable {
        case card
//        case apple
        case bank

        func paymentItem() -> PaymentTypeItem {
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
//            case .apple:
//                return .init(
//                    type: self,
//                    fee: "4%",
//                    time: "instant",
//                    name: "Apple pay",
//                    icon: UIImage.buyApple
//                )
            }
        }
    }

    struct PaymentTypeItem: Equatable {
        var type: PaymentType
        var fee: String
        // TODO: rename to 'duration'
        var time: String
        var name: String
        var icon: UIImage
    }
}


protocol BuyExchangeService {
    func getMinAmount(currency: Buy.Currency) async throws -> Double
    func getMinAmounts(_ currency1: Buy.Currency, _ currency2: Buy.Currency) async throws -> (Double, Double)
    func convert(input: Buy.ExchangeInput, to currency: Buy.Currency) async throws -> Buy.ExchangeOutput
    func getExchangeRate(from fiatCurrency: Buy.FiatCurrency, to cryptoCurrency: Buy.CryptoCurrency)
    async throws -> Buy.ExchangeRate
}

struct MoonpayExchange: BuyExchangeService {
    let provider: Moonpay.Provider

    init(provider: Moonpay.Provider) { self.provider = provider }

    func convert(input: Buy.ExchangeInput, to currency: Buy.Currency) async throws -> Buy.ExchangeOutput {
        let currencies = [input.currency, currency]
        let base = currencies.first { $0 is Buy.FiatCurrency }
        let quote = currencies.first { $0 is Buy.CryptoCurrency }

        guard let base = base as? MoonpayCodeMapping, let quote = quote as? MoonpayCodeMapping
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
                    quoteCurrencyAmount: quoteAmount
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
            if let error = error as? Moonpay.Error {
                switch error {
                case let .message(message: message):
//                    fatalError(message)
                    throw error//Exception.message(message)
                }
            }
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
        Buy.FiatCurrency(rawValue: self.rawValue)
    }
}

extension Token {
    func buyCryptoCurrency() -> Buy.CryptoCurrency? {
        Buy.CryptoCurrency(rawValue: self.symbol.lowercased())
    }
}

//extension Buy.ExchangeOutput: Equatable {
//    static func == (lhs: Buy.ExchangeOutput, rhs: Buy.ExchangeOutput) -> Bool {
//        lhs.amount == rhs.amount &&
//        lhs.total == rhs.total &&
//        lhs.currency.name == rhs.currency.name &&
//        lhs.networkFee == rhs.networkFee &&
//        lhs.processingFee == rhs.processingFee &&
//        lhs.purchaseCost == rhs.purchaseCost
//    }
//}
