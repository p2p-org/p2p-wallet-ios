import Combine
import KeyAppUI
import SolanaSwift
import Resolver

final class SendInputAmountViewModel: BaseViewModel, ObservableObject {
    // MARK: - Nested type

    enum EnteredAmountType {
        case fiat
        case token
    }

    struct Amount {
        let inFiat: Double
        let inToken: Double
    }

    // MARK: - Actions

    let switchPressed = PassthroughSubject<Void, Never>()
    let maxAmountPressed = PassthroughSubject<Void, Never>()
    let changeAmount = PassthroughSubject<(amount: Amount, type: EnteredAmountType), Never>()
    
    // It's a fact of exactly changing amount
    let tokenAmountChanged = PassthroughSubject<Amount?, Never>()

    // MARK: - Properties

    // State
    @Published var token: Wallet {
        didSet { tokenChangedEvent.send(token) }
    }

    @Published var maxAmountToken: Double = 0
    var wasMaxUsed: Bool = false // Analytic param

    // View
    @Published var maxAmountTextInCurrentType = ""
    @Published var amountText: String = ""
    @Published var amountTextColor: UIColor = Asset.Colors.night.color
    @Published var mainTokenText = ""
    @Published var mainAmountType: EnteredAmountType = .fiat
    @Published var isSwitchAvailable = true
    @Published var isMaxButtonVisible: Bool = true

    @Published var secondaryAmountText = ""
    @Published var secondaryCurrencyText = ""

    @Published var isFirstResponder: Bool = false
    @Published var isDisabled = false
    @Published var amount: Amount?
    @Published var isError: Bool = false
    @Published var countAfterDecimalPoint: Int
    @Published var showSecondaryAmounts = true

    private let fiat: Fiat
    private var currentText: String?
    private var tokenChangedEvent = CurrentValueSubject<Wallet, Never>(.init(token: .nativeSolana))

    // MARK: - Dependencies
    private let pricesService: PricesServiceType

    init(initialToken: Wallet) {
        fiat = Defaults.fiat
        token = initialToken
        countAfterDecimalPoint = Constants.fiatDecimals
        mainAmountType = Defaults.isTokenInputTypeChosen ? .token : .fiat
        pricesService = Resolver.resolve(PricesServiceType.self)

        super.init()

        maxAmountPressed
            .sink { [unowned self] in
                self.amountText = self.maxAmountTextInCurrentType
                self.wasMaxUsed = true
                // Manual update of amount due to inaccurate fiat round
                self.amount = Amount(inFiat: maxAmountToken * token.priceInCurrentFiat, inToken: maxAmountToken)
                self.updateSecondaryAmount()
                self.validateAmount()
            }
            .store(in: &subscriptions)

        $amountText
            .sink { [weak self] text in
                guard let self = self else { return }

                let newAmount = Double(text.replacingOccurrences(of: " ", with: ""))
                if let newAmount = newAmount {
                    switch self.mainAmountType {
                    case .token:
                        self.amount = Amount(inFiat: newAmount * self.token.priceInCurrentFiat, inToken: newAmount)
                    case .fiat:
                        self.amount = Amount(inFiat: newAmount, inToken: newAmount / self.token.priceInCurrentFiat)
                    }
                } else {
                    self.amount = nil
                }
                if self.currentText != text, self.mainAmountType == .token {
                    self.tokenAmountChanged.send(self.amount)
                }
                self.updateSecondaryAmount()
                self.validateAmount()
                self.isMaxButtonVisible = text.isEmpty
                self.currentText = text
            }
            .store(in: &subscriptions)

        // Do not subscribe to token publisher directly as it emits the value before changing it (willSet instead of
        // didSet)
        tokenChangedEvent
            .sink { [weak self] token in
                guard let self = self else { return }
                self.updateCurrencyTitles()
                self.updateDecimalsPoint()
                self.validateDecimalsInAmount()
            }
            .store(in: &subscriptions)

        $maxAmountToken
            .sink { [weak self] value in
                guard let self = self else { return }
                switch self.mainAmountType {
                case .token:
                    self.maxAmountTextInCurrentType = value.formatTokenWithDown(decimals: self.token.decimals)
                case .fiat:
                    self.maxAmountTextInCurrentType = (value * self.token.priceInCurrentFiat).formatFiatWithDown()
                }
            }
            .store(in: &subscriptions)

        $isError
            .sink { [weak self] value in
                self?.amountTextColor = value ? Asset.Colors.rose.color : Asset.Colors.night.color
            }
            .store(in: &subscriptions)

        switchPressed
            .sink { [weak self] in
                guard let self = self else { return }
                switch self.mainAmountType {
                case .fiat: self.mainAmountType = .token
                case .token: self.mainAmountType = .fiat
                }
                self.saveInputTypeChoice()
                if let oldAmount = self.amount {
                    // Toggle amount values because inputField is different type now
                    self.amount = Amount(inFiat: oldAmount.inToken, inToken: oldAmount.inFiat)
                }
                self.updateCurrencyTitles()
                self.updateDecimalsPoint()
            }
            .store(in: &subscriptions)

        $mainAmountType
            .sink { [weak self] type in
                guard let self else { return }
                let currentWallet = self.token
                switch type {
                case .fiat:
                    self.mainTokenText = self.fiat.code
                    self.secondaryCurrencyText = currentWallet.token.symbol
                case .token:
                    self.mainTokenText = currentWallet.token.symbol
                    self.secondaryCurrencyText = self.fiat.code
                }
            }
            .store(in: &subscriptions)
    }
}

private extension SendInputAmountViewModel {
    func updateCurrencyTitles() {
        switch mainAmountType {
        case .fiat:
            mainTokenText = fiat.code
            secondaryCurrencyText = token.token.symbol
            maxAmountTextInCurrentType = (maxAmountToken * token.priceInCurrentFiat).formatFiatWithDown()
        case .token:
            mainTokenText = token.token.symbol
            secondaryCurrencyText = fiat.code
            maxAmountTextInCurrentType = maxAmountToken.formatTokenWithDown(decimals: token.decimals)
        }
        updateSecondaryAmount()
        validateAmount()
    }

    func updateSecondaryAmount() {
        switch mainAmountType {
        case .token:
            let fiatAmount = amount?.inToken * token.priceInCurrentFiat
            let minCondition = fiatAmount > 0 && fiatAmount < Constants.minFiatDisplayAmount
            secondaryAmountText = minCondition ? L10n
                .lessThan(Constants.minFiatDisplayAmount.formatFiatWithDown()) : fiatAmount.formatFiatWithDown()

        case .fiat:
            secondaryAmountText = (amount?.inFiat / token.priceInCurrentFiat)
                .formatTokenWithDown(decimals: token.decimals)
        }
    }

    func validateAmount() {
        changeAmount.send((amount ?? .zero, mainAmountType))
    }

    func validateDecimalsInAmount() {
        // Cut decimals in token input if its count is changed
        switch mainAmountType {
        case .token:
            guard let amountInToken = amount?.inToken else { return }
            amountText = amountInToken.formatTokenWithDown(decimals: token.decimals)
        case .fiat:
            break
        }
    }

    func updateDecimalsPoint() {
        countAfterDecimalPoint = mainAmountType == .token ? token.decimals : Constants.fiatDecimals
    }

    func saveInputTypeChoice() {
        Defaults.isTokenInputTypeChosen = mainAmountType == .token
    }
}

private extension Wallet {
    var decimals: Int { Int(token.decimals) }
}

private enum Constants {
    static let fiatDecimals = 2
    static let minFiatDisplayAmount = 0.01
}

private extension SendInputAmountViewModel.Amount {
    static let zero = SendInputAmountViewModel.Amount(inFiat: .zero, inToken: .zero)
}

private extension Double {
    func formatFiatWithDown() -> String {
        toString(maximumFractionDigits: Constants.fiatDecimals, roundingMode: .down)
    }

    func formatTokenWithDown(decimals: Int) -> String {
        toString(maximumFractionDigits: decimals, roundingMode: .down)
    }
}
