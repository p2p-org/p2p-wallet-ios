// swiftlint:disable file_length
import AnalyticsManager
import Combine
import Foundation
import KeyAppUI
import Resolver
import SolanaSwift
import SwiftyUserDefaults
import UIKit
import Moonpay

let MoonpayLicenseURL = "https://www.moonpay.com/legal/licenses"

private extension String {
    static let neutralFlag = "🏳️‍🌈"
}

final class BuyViewModel: ObservableObject {
    
    typealias IpInfo = Moonpay.Provider.IpAddressResponse
    
    var coordinatorIO = CoordinatorIO()

    // MARK: - To View

    @Published var state: State = .usual
    @Published var flag = String.neutralFlag
    @Published var availableMethods = [PaymentTypeItem]()
    @Published var token: Token
    @Published var fiat: Fiat = .usd
    @Published var tokenAmount: String = ""
    @Published var fiatAmount: String = BuyViewModel.defaultMinAmount.toString()
    @Published var total: String = ""
    @Published var selectedPayment: PaymentType = .card
    @Published var isLoading = false
    @Published var areMethodsLoading = true
    @Published var isLeftFocus = false
    @Published var isRightFocus = false
    @Published var exchangeOutput: Buy.ExchangeOutput?
    @Published var navigationSlidingPercentage: CGFloat = 1
    @Published var targetSymbol: String?
    @Published var buttonItem: ButtonItem = .init(
        title: L10n.buy + " \(defaultToken.symbol)",
        icon: .buyWallet,
        enabled: true
    )

    // MARK: -

    private var subscriptions = Set<AnyCancellable>()
    private var isGBPBankTransferEnabled = false
    private var isBankTransferEnabled = false
//    private var minAmounts = [Fiat: Double]()
    private var isEditingFiat: Bool { !isLeftFocus }

    // Dependencies
    @Injected private var moonpayProvider: Moonpay.Provider
    @Injected var exchangeService: BuyExchangeService
    @Injected var walletsRepository: WalletsRepository
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var pricesService: PricesServiceType

    // Defaults
//    @SwiftyUserDefault(keyPath: \.buyLastPaymentMethod, options: .cached)
    var lastMethod: PaymentType = .bank
    @SwiftyUserDefault(keyPath: \.buyMinPrices, options: .cached)
    var buyMinPrices: [String: [String: Double]]
    private var countryTitle: String?

    private var tokenPrices: [Fiat: [String: Double?]] = [:]

    // Defaults
    private static let defaultMinAmount = Double(30)
    private static let defaultMaxAmount = Double(10000)
    private static let tokens: [Token] = [.usdc, .nativeSolana]
    private static let fiats: [Fiat] = available(.buyBankTransferEnabled) ? [.eur, .gbp, .usd] : [.usd]
    private static let defaultToken = Token.usdc
    
    // MARK: - Init

    init(
        defaultToken: Token? = nil,
        targetSymbol: String? = nil
    ) {
        self.targetSymbol = targetSymbol

        if let defaultToken = defaultToken {
            token = defaultToken
        } else {
            token = BuyViewModel.defaultToken
        }

        fiatAmount = String(
            buyMinPrices[Fiat.usd.rawValue]?[Token.nativeSolana.symbol] ??
                BuyViewModel.defaultMinAmount
        )

        var initTokenWasSelected = false
        var initFiatWasSelected = false

        coordinatorIO.tokenSelected
            .sink { [unowned self] token in
                let oldToken = self.token
                self.token = token ?? self.token
                if initTokenWasSelected {
                    analyticsManager.log(event: .buyCoinChanged(
                        fromCoin: oldToken.symbol,
                        toCoin: self.token.symbol
                    ))
                }
                initTokenWasSelected = true
            }
            .store(in: &subscriptions)

        coordinatorIO.fiatSelected
            .sink { [unowned self] fiat in
                let oldFiat = self.fiat
                self.fiat = fiat ?? self.fiat
                Task {
                    if isGBPBankTransferEnabled, fiat != .gbp {
                        await setPaymentMethod(.card)
                    } else if isBankTransferEnabled, fiat != .eur {
                        await setPaymentMethod(.card)
                    }
                }
                if initFiatWasSelected {
                    analyticsManager.log(event: .buyCurrencyChanged(
                        fromCurrency: oldFiat.code,
                        toCurrency: self.fiat.code
                    ))
                }
                initFiatWasSelected = true
            }
            .store(in: &subscriptions)

        coordinatorIO.navigationSlidingPercentage.sink { percentage in
            self.navigationSlidingPercentage = percentage * 110 * 2
        }.store(in: &subscriptions)

        totalPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { value in
                self.total = value.total.fiatAmountFormattedString(
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

        form.debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .map { aFiat, aToken, anAmount, _ in
                var enabled = true
                var icon: UIImage? = .buyWallet
                var title = L10n.buy + " \(self.token.symbol)"
                let minAmount = (self.buyMinPrices[aFiat.rawValue]?[aToken.name] ?? BuyViewModel.defaultMinAmount)
                if minAmount > anAmount {
                    title = L10n.minimalTransactionIs(
                        minAmount.fiatAmountFormattedString(
                            maximumFractionDigits: 2,
                            currency: self.fiat
                        )
                    )
                    icon = nil
                    enabled = false
                } else if anAmount > BuyViewModel.defaultMaxAmount {
                    title = L10n.maximumTransactionIs(
                        BuyViewModel.defaultMaxAmount.fiatAmountFormattedString(
                            maximumFractionDigits: 2,
                            currency: self.fiat
                        )
                    )
                    icon = nil
                    enabled = false
                }
                return ButtonItem(title: title, icon: icon, enabled: enabled)
            }
            .removeDuplicates()
            .assignWeak(to: \.buttonItem, on: self)
            .store(in: &subscriptions)

        areMethodsLoading = true

        Task {
            for fiat in BuyViewModel.fiats {
                self.tokenPrices[fiat] =
                    try await pricesService.getCurrentPrices(
                        tokens: BuyViewModel.tokens,
                        toFiat: fiat
                    )
                    .mapValues { $0.value }
            }

            let buyBankEnabled = available(.buyBankTransferEnabled)
            let banks = buyBankEnabled ? try await exchangeService.isBankTransferEnabled() : (gbp: false, eur: false)
            self.isBankTransferEnabled = banks.eur && buyBankEnabled
            self.isGBPBankTransferEnabled = banks.gbp && buyBankEnabled
            await self.setPaymentMethod(self.lastMethod)

            // Buy min price is used to cache min price values. Doesnt need to implemet it at the moment
            self.buyMinPrices = [:]
//    var minPrices = [String: [String: Double]]()
//    for aFiat in [Fiat.usd, Fiat.eur, Fiat.gbp] {
//        for aToken in [Token.nativeSolana, Token.usdc] {
//            guard
//                let from = aFiat.buyFiatCurrency(),
//                let to = aToken.buyCryptoCurrency() else { continue }
//            if let amount = self.buyMinPrices[aFiat.rawValue]?[aToken.symbol] {
//                if minPrices[aFiat.rawValue] == nil {
//                    minPrices[aFiat.rawValue] = [:]
//                }
//                minPrices[aFiat.rawValue]?[aToken.symbol] = amount
//            } else {
//                let result = try? await self.exchangeService.getMinAmounts(from, to)
//                guard result?.0 ?? 0 > 0 else { continue }
//                if minPrices[aFiat.rawValue] == nil {
//                    minPrices[aFiat.rawValue] = [:]
//                }
//                minPrices[aFiat.rawValue]?[aToken.symbol] = result?.0 ?? BuyViewModel.defaultMinAmount
//            }
//        }
//    }
//    self.buyMinPrices = minPrices

            DispatchQueue.main.async {
                // USD only if bank is unavailable
                self.fiat = self.lastMethod == .bank ?
                    self.isGBPBankTransferEnabled ? .gbp :
                    (self.isBankTransferEnabled ? .eur : .usd) : .usd

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
        
        getBuyAvailability()
    }
    
    private func getBuyAvailability() {
        Task {
            let ipInfo = try await moonpayProvider.ipAddresses()
            await MainActor.run {
                setNewCountryInfo(
                    flag: ipInfo.alpha2.asFlag ?? .neutralFlag,
                    title: ipInfo.countryTitle,
                    isBuyAllowed: ipInfo.isBuyAllowed
                )
            }
        }
    }
    
    private func setNewCountryInfo(flag: String, title: String, isBuyAllowed: Bool) {
        guard !title.isEmpty else {
            state = .usual
            self.flag = .neutralFlag
            return
        }
        
        if isBuyAllowed {
            state = .usual
        } else {
            let model = ChangeCountryErrorView.ChangeCountryModel(
                image: .connectionErrorCat,
                title: L10n.sorry,
                subtitle: L10n.unfortunatelyYouCanNotBuyInButYouCanStillUseOtherKeyAppFeatures(title),
                buttonTitle: L10n.goBack,
                subButtonTitle: L10n.changeTheRegionManually
            )
            state = .buyNotAllowed(model: model)
        }
        self.flag = flag
        self.countryTitle = title
    }
    
    // MARK: - From View
    
    func goBackClicked() {
        coordinatorIO.close.send()
    }
    
    func changeTheRegionClicked() {
        coordinatorIO.chooseCountry.send(SelectCountryViewModel.Model(
            flag: flag,
            title: countryTitle ?? ""
        ))
    }
    
    // MARK: -

    @MainActor func didSelectPayment(_ payment: PaymentTypeItem) {
        selectedPayment = payment.type
        setPaymentMethod(payment.type)
        analyticsManager.log(event: .buyChosenMethodPayment(type: payment.type.analyticName))
    }

    @MainActor private func setPaymentMethod(_ payment: PaymentType) {
        guard availablePaymentTypes().contains(payment) else {
            // Card always available
            selectedPayment = .card
            lastMethod = selectedPayment
            return
        }
        selectedPayment = payment
        lastMethod = payment

        if payment == .bank {
            if isGBPBankTransferEnabled {
                fiat = .gbp
            } else if isBankTransferEnabled {
                fiat = .eur
            }
        }
        // Uncomment in future
        // If selected payment doesnt have current currency
        // - changing to the fist one from allowed
//        if !availableFiat(payment: selectedPayment).contains(fiat) {
//            fiat = availableFiat(payment: selectedPayment).first ?? .usd
//        }
    }

    func totalTapped() async throws {
        guard let exchangeOutput = exchangeOutput else { return }
        do {
            guard
                let fiat = fiat.buyFiatCurrency(),
                let token = token.buyCryptoCurrency()
            else { return }
            let exchangeRate = try await exchangeService
                .getExchangeRate(from: fiat, to: token)
            coordinatorIO.showDetail.send(
                (
                    exchangeOutput,
                    exchangeRate: exchangeRate.amount,
                    fiat: self.fiat,
                    token: self.token
                )
            )
        }
    }

    func tokenSelectTapped() {
        let tokens = BuyViewModel.tokens
        coordinatorIO.showTokenSelect.send(
            tokens.map {
                TokenCellViewItem(
                    token: $0,
                    amount: tokenPrices[fiat]?[token.address] ?? 0,
                    fiat: fiat
                )
            }
        )
    }

    func fiatSelectTapped() {
        let fiats = availableFiat(payment: selectedPayment)
        guard fiats.count > 1 else { return }
        coordinatorIO.showFiatSelect.send(fiats)
    }

    func buyButtonTapped() {
        guard
            let from = fiat.buyFiatCurrency(),
            let to = token.buyCryptoCurrency(),
            let amount = Double(fiatAmount.fiatFormat),
            let url = try? getExchangeURL(
                from: from,
                to: to,
                amount: amount
            ) else { return }
        coordinatorIO.buy.send(url)

        var typeBankTransfer: String?
        if case .bank = selectedPayment {
            if isGBPBankTransferEnabled {
                typeBankTransfer = "gbp_bank_transfer"
            } else {
                typeBankTransfer = "sepa_bank_transfer"
            }
        }
        analyticsManager.log(event: .buyButtonPressed(
            sumCurrency: fiatAmount,
            sumCoin: tokenAmount,
            currency: from.name,
            coin: to.name,
            paymentMethod: selectedPayment.analyticName,
            bankTransfer: typeBankTransfer != nil,
            typeBankTransfer: typeBankTransfer
        ))
        analyticsManager.log(event: .moonpayWindowOpened)
    }

    func moonpayLicenseTap() {
        let url = MoonpayLicenseURL
        coordinatorIO.license.send(URL(string: url)!)
    }

    // MARK: -

    var form: AnyPublisher<(Buy.FiatCurrency, Buy.CryptoCurrency, Double, Double), Never> {
        Publishers.CombineLatest4(
            $fiat.removeDuplicates().compactMap { $0.buyFiatCurrency() },
            $token.removeDuplicates().compactMap { $0.buyCryptoCurrency() },
            $fiatAmount.map { Double($0.fiatFormat) ?? 0 }.removeDuplicates(),
            $tokenAmount.map { Double($0.cryptoCurrencyFormat) ?? 0 }.removeDuplicates()
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
            let newPayment = (self.isGBPBankTransferEnabled && paymentType == .bank) ?
                PaymentType.gbpBank :
                paymentType
            return (from, to, amount, newPayment)
        }
        .removeDuplicates(by: { aLeft, aRight in
            let currencies = aLeft.0.isEqualTo(aRight.0) && aLeft.1.isEqualTo(aRight.1)
            let amounts = aLeft.2 == aRight.2 && aLeft.3 == aRight.3
            return currencies && amounts
        }).handleEvents(receiveOutput: { [weak self] _ in
            DispatchQueue.main.async {
                self?.isLoading = true
            }
        }).map { from, to, amount, paymentType -> AnyPublisher<Buy.ExchangeOutput?, Never> in
            self.exchange(
                from: from,
                to: to,
                amount: amount,
                paymentType: paymentType
            )
            .map(Optional.init)
            .replaceError(with: nil)
            .eraseToAnyPublisher()
        }
        .subscribe(on: DispatchQueue.global())
        .receive(on: DispatchQueue.main)
        // Getting only last request
        .switchToLatest()
        .handleEvents(receiveOutput: { [weak self] output in
            DispatchQueue.main.async {
                if output == nil {
                    // removing calculated value on error
                    if self?.isEditingFiat == true {
                        self?.tokenAmount = "0".cryptoCurrencyFormat
                    } else {
                        self?.fiatAmount = "0".fiatFormat
                    }
                }
                self?.isLoading = false
            }
        })
        .compactMap { $0 }
        .eraseToAnyPublisher()
    }

    func exchange(
        from: BuyCurrencyType,
        to: BuyCurrencyType,
        amount: Double,
        paymentType: PaymentType
    ) -> AnyPublisher<Buy.ExchangeOutput, Error> {
        Future { promise in
            Task { [weak self] in
                guard let self = self else { return }
                try Task.checkCancellation()
                do {
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
                } catch {
                    promise(.failure(error))
                }
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
        // HACK
        let paymentMethod = isGBPBankTransferEnabled ? "gbp_bank" : selectedPayment.rawValue
        let provider = try factory.create(
            walletRepository: walletsRepository,
            fromCurrency: from,
            amount: amount,
            toCurrency: to,
            paymentMethod: paymentMethod
        )
        return URL(string: provider.getUrl())!
    }

    func availableFiat(payment _: PaymentType) -> [Fiat] {
        if isBankTransferEnabled || isGBPBankTransferEnabled || available(.buyBankTransferEnabled) {
            return BuyViewModel.fiats
        }
        return [.usd]
        // Uncomment in future
//        switch payment {
//        case .card:
//            if !isBankTransferEnabled && !isGBPBankTransferEnabled {
//                return [.usd]
//            }
//            return [.eur, .gbp, .usd]
//        case .bank:
//            return isGBPBankTransferEnabled ? [.gbp] : [.eur]
//        }
    }

    func availablePaymentTypes() -> [PaymentType] {
        PaymentType.allCases.filter {
            if case .bank = $0 {
                return isBankTransferEnabled || isGBPBankTransferEnabled
            }
            return true
        }
    }
    
    func countrySelected(_ country: SelectCountryViewModel.Model, buyAllowed: Bool) {
        setNewCountryInfo(flag: country.flag, title: country.title, isBuyAllowed: buyAllowed)
    }

    struct CoordinatorIO {
        
        // To Coordinator
        let showDetail = PassthroughSubject<(
            Buy.ExchangeOutput,
            exchangeRate: Double,
            fiat: Fiat,
            token: Token
        ), Never>()
        let showTokenSelect = PassthroughSubject<[TokenCellViewItem], Never>()
        let showFiatSelect = PassthroughSubject<[Fiat], Never>()
        let navigationSlidingPercentage = PassthroughSubject<CGFloat, Never>()
        let chooseCountry = PassthroughSubject<SelectCountryViewModel.Model, Never>()
        
        // From Coordinator
        let tokenSelected = CurrentValueSubject<Token?, Never>(nil)
        let fiatSelected = CurrentValueSubject<Fiat?, Never>(nil)
        let buy = PassthroughSubject<URL, Never>()
        let license = PassthroughSubject<URL, Never>()
        let close = PassthroughSubject<Void, Never>()
    }

    struct ButtonItem: Equatable {
        var title: String
        var icon: UIImage?
        var enabled: Bool
    }
}

// MARK: - State

extension BuyViewModel {
    enum State {
        case usual
        case buyNotAllowed(model: ChangeCountryErrorView.ChangeCountryModel)
    }
}

// MARK: - Country Title

extension Moonpay.Provider.IpAddressResponse {
    var countryTitle: String {
        country + (alpha2 == "US" ? " (\(state))" : "")
    }
}
