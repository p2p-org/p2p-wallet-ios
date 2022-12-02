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
    @Published var token: Wallet = .nativeSolana(pubkey: nil, lamport: nil)
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

    override init() {
        fiat = Defaults.fiat

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
                switch self.mainAmountType {
                case .token:
                    self
                        .secondaryAmountText =
                        "\((self.amount * self.token.priceInCurrentFiat).toString(maximumFractionDigits: 9)) \(self.token.token.symbol)"
                case .fiat:
                    self
                        .secondaryAmountText =
                        "\((self.amount / self.token.priceInCurrentFiat).toString(maximumFractionDigits: 9)) \(self.fiat.code)"
                }
                self.changeAmount.send((self.amount ?? 0, self.mainAmountType))
            }
            .store(in: &subscriptions)

        $token
            .sink { [weak self] value in
                guard let self = self else { return }
                switch self.mainAmountType {
                case .token:
                    self.mainTokenText = value.token.symbol
                case .fiat:
                    self.secondaryCurrencyText = value.token.symbol
                }
            }
            .store(in: &subscriptions)

        $maxAmountToken
            .sink { [weak self] value in
                guard let self = self else { return }
                switch self.mainAmountType {
                case .token:
                    self.maxAmountTextInCurrentType = value.toString(maximumFractionDigits: 9)
                case .fiat:
                    self.maxAmountTextInCurrentType = (value * self.token.priceInCurrentFiat)
                        .toString(maximumFractionDigits: 9)
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
            }
            .store(in: &subscriptions)

        $mainAmountType
            .sink { [weak self] value in
                guard let self = self else { return }
                switch value {
                case .fiat:
                    self.mainTokenText = self.fiat.code
                    self.secondaryCurrencyText = self.token.token.symbol
                    self.secondaryAmountText = "\(self.amount / self.token.priceInCurrentFiat) \(self.fiat.code)"
                    self.maxAmountTextInCurrentType = (self.maxAmountToken * self.token.priceInCurrentFiat)
                        .toString(maximumFractionDigits: 9)
                case .token:
                    self.mainTokenText = self.token.token.symbol
                    self.secondaryCurrencyText = self.fiat.code
                    self.secondaryAmountText = "\(self.amount * self.token.priceInCurrentFiat) \(self.token.token.symbol)"
                    self.maxAmountTextInCurrentType = self.maxAmountToken.toString(maximumFractionDigits: 9)
                }
                self.changeAmount.send((self.amount ?? 0, self.mainAmountType))
            }
            .store(in: &subscriptions)
    }
}
