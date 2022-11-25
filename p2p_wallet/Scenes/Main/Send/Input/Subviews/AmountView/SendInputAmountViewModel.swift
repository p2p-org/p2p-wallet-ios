import Combine
import SolanaSwift
import KeyAppUI

final class SendInputAmountViewModel: ObservableObject {
    enum EnteredAmountType {
        case fiat
        case token
    }

    let switchPressed = PassthroughSubject<Void, Never>()
    let maxAmountPressed = PassthroughSubject<Void, Never>()
    let changeAmount = PassthroughSubject<(Double, EnteredAmountType), Never>()

    @Published var token: Wallet = .nativeSolana(pubkey: nil, lamport: nil)

    @Published var amountText = ""
    @Published var amountTextColor: UIColor = Asset.Colors.night.color
    @Published var mainTokenText = ""
    @Published var mainAmountType: EnteredAmountType = .fiat

    @Published var secondaryAmountText = ""
    @Published var secondaryCurrencyText = ""

    @Published var isFirstResponder: Bool = false
    @Published var maxAmount: Double = 0
    @Published var amount: Double = 0
    @Published var isError: Bool = false

    private let fiat: Fiat

    private var subscriptions = Set<AnyCancellable>()

    init() {
        fiat = Defaults.fiat

        maxAmountPressed
            .sink { [unowned self] in
                self.amountText = self.maxAmount.toString()
            }
            .store(in: &subscriptions)

        $amountText
            .sink { [weak self] text in
                guard let self = self else { return }

                self.amount = Double(text) ?? 0.0
                self.secondaryAmountText = (self.amount * self.token.priceInCurrentFiat).toString() // TODO: fix
            }
            .store(in: &subscriptions)

        $token
            .sink { [weak self] value in
                guard let self = self else { return }
                self.maxAmount = value.amount ?? 0
                switch self.mainAmountType {
                case .token:
                    self.mainTokenText = value.token.symbol
                case .fiat:
                    self.secondaryCurrencyText = value.token.symbol
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
                    self.maxAmount = self.token.amountInCurrentFiat
                    self.amountText = "\(self.amount * self.token.priceInCurrentFiat)"
                case .token:
                    self.mainTokenText = self.token.token.symbol
                    self.secondaryCurrencyText = self.fiat.symbol
                    self.maxAmount = self.token.amount ?? 0
                    self.amountText = "\(self.amount * self.token.price?.value)"
                }
            }
            .store(in: &subscriptions)
    }
}
