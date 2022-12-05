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

    private let fiat: Fiat

    init(initialToken: Wallet) {
        fiat = Defaults.fiat
        token = initialToken

        super.init()

        maxAmountPressed
            .sink { [unowned self] in
                self.amountText = self.maxAmountTextInCurrentType
            }
            .store(in: &subscriptions)

        $amountText
            .sink { [weak self] text in
                guard let self = self else { return }

                self.amount = Double(text)
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
                    self.maxAmountTextInCurrentType = value.formatted()
                case .fiat:
                    self.maxAmountTextInCurrentType = (value * self.token.priceInCurrentFiat).formatted()
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
            self.maxAmountTextInCurrentType = (self.maxAmountToken * currentWallet.priceInCurrentFiat).formatted()
        case .token:
            self.mainTokenText = currentWallet.token.symbol
            self.secondaryCurrencyText = self.fiat.code
            self.maxAmountTextInCurrentType = self.maxAmountToken.formatted()
        }
        self.updateSecondaryAmount(for: currentWallet)
        self.changeAmount.send((self.amount ?? 0, self.mainAmountType))
    }

    func updateSecondaryAmount(for wallet: Wallet? = nil) {
        let currentWallet = wallet ?? self.token
        switch self.mainAmountType {
        case .token:
            self.secondaryAmountText = "\((self.amount * currentWallet.priceInCurrentFiat).formatted()) \(self.fiat.code)"
        case .fiat:
            self.secondaryAmountText = "\((self.amount / currentWallet.priceInCurrentFiat).formatted()) \(currentWallet.token.symbol)"
        }
    }
}

private extension Double {
    func formatted() -> String {
        return self.toString(maximumFractionDigits: 9)
    }
}
