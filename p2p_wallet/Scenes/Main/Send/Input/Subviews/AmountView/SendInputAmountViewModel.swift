import Combine
import KeyAppUI
import SolanaSwift

final class SendInputAmountViewModel: BaseViewModel, ObservableObject {
    enum EnteredAmountType {
        case fiat
        case token
    }

    struct Amount {
        let inFiat: Double
        let inToken: Double
    }

    let switchPressed = PassthroughSubject<Void, Never>()
    let maxAmountPressed = PassthroughSubject<Void, Never>()
    let changeAmount = PassthroughSubject<(amount: Amount, type: EnteredAmountType), Never>()

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
    @Published var mainAmountType: EnteredAmountType
    @Published var isMaxButtonVisible: Bool = true

    @Published var secondaryAmountText = ""
    @Published var secondaryCurrencyText = ""

    @Published var isFirstResponder: Bool = false
    @Published var amount: Amount?
    @Published var isError: Bool = false
    @Published var countAfterDecimalPoint: Int

    private let fiat: Fiat
    private var tokenChangedEvent = CurrentValueSubject<Wallet, Never>(.init(token: .nativeSolana))

    init(initialToken: Wallet) {
        fiat = Defaults.fiat
        token = initialToken
        countAfterDecimalPoint = Constants.fiatDecimals
        mainAmountType = Defaults.isTokenInputTypeChosen ? .token : .fiat
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
                self.updateSecondaryAmount()
                self.validateAmount()
                self.isMaxButtonVisible = text.isEmpty
            }
            .store(in: &subscriptions)

        // Do not subscribe to token publisher directly as it emits the value before changing it (willSet instead of didSet)
        tokenChangedEvent
            .sink { [weak self] _ in
                self?.updateCurrencyTitles()
                self?.updateDecimalsPoint()
                self?.validateDecimalsInAmount()
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
    }
}

private extension SendInputAmountViewModel {
    func updateCurrencyTitles() {
        switch mainAmountType {
        case .fiat:
            self.mainTokenText = self.fiat.code
            self.secondaryCurrencyText = token.token.symbol
            self.maxAmountTextInCurrentType = (self.maxAmountToken * token.priceInCurrentFiat).formatFiatWithDown()
        case .token:
            self.mainTokenText = token.token.symbol
            self.secondaryCurrencyText = self.fiat.code
            self.maxAmountTextInCurrentType = self.maxAmountToken.formatTokenWithDown(decimals: token.decimals)
        }
        self.updateSecondaryAmount()
        self.validateAmount()
    }

    func updateSecondaryAmount() {
        switch self.mainAmountType {
        case .token:
            let fiatAmount = self.amount?.inToken * token.priceInCurrentFiat
            let minCondition = fiatAmount > 0 && fiatAmount < Constants.minFiatDisplayAmount
            self.secondaryAmountText = minCondition ? L10n.lessThan(Constants.minFiatDisplayAmount.formatFiatWithDown()) : fiatAmount.formatFiatWithDown()

        case .fiat:
            self.secondaryAmountText = (self.amount?.inFiat / token.priceInCurrentFiat).formatTokenWithDown(decimals: token.decimals)
        }
    }

    func validateAmount() {
        changeAmount.send((self.amount ?? .zero, mainAmountType))
    }

    func validateDecimalsInAmount() {
        // Cut decimals in token input if its count is changed
        switch mainAmountType {
        case .token:
            guard let amountInToken = self.amount?.inToken else { return }
            self.amountText = amountInToken.formatTokenWithDown(decimals: token.decimals)
        case .fiat:
            break
        }
    }

    func updateDecimalsPoint() {
        self.countAfterDecimalPoint = self.mainAmountType == .token ? token.decimals : Constants.fiatDecimals
    }

    func saveInputTypeChoice() {
        Defaults.isTokenInputTypeChosen = self.mainAmountType == .token
    }
}

private extension Wallet {
    var decimals: Int { Int(self.token.decimals) }
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
        return self.toString(maximumFractionDigits: Constants.fiatDecimals, roundingMode: .down)
    }

    func formatTokenWithDown(decimals: Int) -> String {
        return self.toString(maximumFractionDigits: decimals, roundingMode: .down)
    }
}
