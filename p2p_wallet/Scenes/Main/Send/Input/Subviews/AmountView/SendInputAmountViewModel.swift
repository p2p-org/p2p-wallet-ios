import Combine
import SolanaSwift
import KeyAppUI

final class SendInputAmountViewModel: ObservableObject {
    let switchPressed = PassthroughSubject<Void, Never>()
    let maxAmountPressed = PassthroughSubject<Void, Never>()

    @Published var token: Wallet = .nativeSolana(pubkey: nil, lamport: nil)

    @Published var amountText = ""
    @Published var amountTextColor: UIColor = Asset.Colors.night.color

    @Published var isFirstResponder: Bool = false
    @Published var tokenText = ""
    @Published var switchToken = "USDC"
    @Published var anotherToken = "129.02 USD"
    @Published var maxAmount: Double = 0
    @Published var amount: Double = 0
    @Published var isError: Bool = false

    private var subscriptions = Set<AnyCancellable>()

    init() {
        maxAmountPressed
            .sink { [unowned self] in
                self.amountText = "\(self.maxAmount)"
            }
            .store(in: &subscriptions)

        $amountText
            .sink { [weak self] text in
                self?.amount = Double(text) ?? 0.0
            }
            .store(in: &subscriptions)

        $token
            .sink { [weak self] value in
                guard let self = self else { return }
                self.maxAmount = value.amount ?? 0
                self.tokenText = value.token.symbol
            }
            .store(in: &subscriptions)

        $isError
            .sink { [weak self] value in
                self?.amountTextColor = value ? Asset.Colors.rose.color : Asset.Colors.night.color
            }
            .store(in: &subscriptions)
    }
}
