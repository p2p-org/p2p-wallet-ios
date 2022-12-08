import Combine
import KeyAppUI
import SolanaSwift

final class SendInputAmountViewModel: BaseViewModel, ObservableObject {
    enum EnteredAmountType {
        case fiat
        case token
    }

    let switchPressed = PassthroughSubject<Void, Never>()
    let maxAmountPressed = PassthroughSubject<Void, Never>()
    let changeAmount = PassthroughSubject<(amount: Double, type: EnteredAmountType), Never>()

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

    @Published var secondaryAmountText = ""
    @Published var secondaryCurrencyText = ""

    @Published var isFirstResponder: Bool = false
    @Published var amount: Double? = nil
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
            }
            .store(in: &subscriptions)

        $amountText
            .sink { [weak self] text in
                guard let self = self else { return }

                self.amount = Double(text.replacingOccurrences(of: " ", with: ""))
                self.updateSecondaryAmount()
                self.changeAmount.send((self.amount ?? 0, self.mainAmountType))
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
                    self.maxAmountTextInCurrentType = value.toString(maximumFractionDigits: self.token.decimals)
                case .fiat:
                    self.maxAmountTextInCurrentType = (value * self.token.priceInCurrentFiat).toString(maximumFractionDigits: Constants.fiatDecimals)
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
            self.maxAmountTextInCurrentType = (self.maxAmountToken * currentWallet.priceInCurrentFiat).toString(maximumFractionDigits: Constants.fiatDecimals)
        case .token:
            self.mainTokenText = currentWallet.token.symbol
            self.secondaryCurrencyText = self.fiat.code
            self.maxAmountTextInCurrentType = self.maxAmountToken.toString(maximumFractionDigits: currentWallet.decimals)
        }
        self.updateSecondaryAmount(for: currentWallet)
        self.changeAmount.send((self.amount ?? 0, self.mainAmountType))
    }

    func updateSecondaryAmount(for wallet: Wallet? = nil) {
        let currentWallet = wallet ?? self.token
        switch self.mainAmountType {
        case .token:
            self.secondaryAmountText = [(self.amount * currentWallet.priceInCurrentFiat).toString(maximumFractionDigits: Constants.fiatDecimals), self.fiat.code].joined(separator: " ")

        case .fiat:
            self.secondaryAmountText = (self.amount / currentWallet.priceInCurrentFiat).tokenAmount(symbol: currentWallet.token.symbol, maximumFractionDigits: currentWallet.decimals)
        }
    }
}

private extension Wallet {
    var decimals: Int { Int(self.token.decimals) }
}

private enum Constants {
    static let fiatDecimals = 2
}
