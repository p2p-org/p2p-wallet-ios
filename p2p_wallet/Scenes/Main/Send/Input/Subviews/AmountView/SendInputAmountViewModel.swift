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
    @Published var token: Wallet
    @Published var maxAmountToken: Double = 0
    var wasMaxUsed: Bool = false // Analytic param

    // View
    @Published var maxAmountTextInCurrentType = ""
    @Published var amountText: String = ""
    @Published var amountTextColor: UIColor = Asset.Colors.night.color
    @Published var mainTokenText = ""
    @Published var mainAmountType: EnteredAmountType = .fiat
    @Published var isMaxButtonVisible: Bool = true

    @Published var secondaryAmountText = ""
    @Published var secondaryCurrencyText = ""

    @Published var isFirstResponder: Bool = false
    @Published var isDisabled = false
    @Published var amount: Amount?
    @Published var isError: Bool = false
    @Published var countAfterDecimalPoint: Int

    private let fiat: Fiat

    init(initialToken: Wallet) {
        fiat = Defaults.fiat
        token = initialToken
        countAfterDecimalPoint = Constants.fiatDecimals

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

        $token
            .sink { [weak self] value in
                self?.updateCurrencyTitles(for: value)
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
                if let oldAmount = self.amount {
                    // Toggle amount values because inputField is different type now
                    self.amount = Amount(inFiat: oldAmount.inToken, inToken: oldAmount.inFiat)
                }
                self.updateCurrencyTitles()
                self.countAfterDecimalPoint = self.mainAmountType == .token ? self.token.decimals : Constants.fiatDecimals
            }
            .store(in: &subscriptions)
    }
}

private extension SendInputAmountViewModel {
    func updateCurrencyTitles(for wallet: Wallet? = nil) {
        let currentWallet = wallet ?? self.token
        switch mainAmountType {
        case .fiat:
            self.mainTokenText = self.fiat.code
            self.secondaryCurrencyText = currentWallet.token.symbol
            self.maxAmountTextInCurrentType = (self.maxAmountToken * currentWallet.priceInCurrentFiat).formatFiatWithDown()
        case .token:
            self.mainTokenText = currentWallet.token.symbol
            self.secondaryCurrencyText = self.fiat.code
            self.maxAmountTextInCurrentType = self.maxAmountToken.formatTokenWithDown(decimals: currentWallet.decimals)
        }
        self.updateSecondaryAmount(for: currentWallet)
        self.validateAmount()
    }

    func updateSecondaryAmount(for wallet: Wallet? = nil) {
        let currentWallet = wallet ?? self.token
        switch self.mainAmountType {
        case .token:
            self.secondaryAmountText = (self.amount?.inToken * currentWallet.priceInCurrentFiat).formatFiatWithDown()

        case .fiat:
            self.secondaryAmountText = (self.amount?.inFiat / currentWallet.priceInCurrentFiat).formatTokenWithDown(decimals: currentWallet.decimals)
        }
    }

    func validateAmount() {
        changeAmount.send((self.amount ?? .zero, mainAmountType))
    }
}

private extension Wallet {
    var decimals: Int { Int(self.token.decimals) }
}

private enum Constants {
    static let fiatDecimals = 2
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
