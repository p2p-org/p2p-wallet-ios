import Combine
import SolanaSwift

final class SendInputTokenViewModel: BaseViewModel, ObservableObject {
    let changeTokenPressed = PassthroughSubject<Void, Never>()

    @Published var token: Wallet

    @Published var tokenName: String
    @Published var amountText: String = ""
    @Published var amountInCurrentFiat: Double? = nil
    @Published var isTokenChoiceEnabled: Bool = true

    init(initialToken: Wallet) {
        token = initialToken
        tokenName = initialToken.token.name
        super.init()

        $token
            .sink { [weak self] value in
                guard let self = self else { return }
                self.amountText = value.amount?.tokenAmount(symbol: value.token.symbol) ?? ""
                self.amountInCurrentFiat = value.amountInCurrentFiat
                self.tokenName = value.token.name
            }
            .store(in: &subscriptions)
    }
}
