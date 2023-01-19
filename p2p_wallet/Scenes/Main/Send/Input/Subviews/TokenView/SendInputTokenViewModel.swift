import Combine
import SolanaSwift

final class SendInputTokenViewModel: BaseViewModel, ObservableObject {
    let changeTokenPressed = PassthroughSubject<Void, Never>()

    @Published var token: Wallet

    @Published var tokenName: String
    @Published var amountText: String = ""
    @Published var amountCurrency: String = ""
    @Published var amountInCurrentFiat: String = ""
    @Published var isTokenChoiceEnabled: Bool = true

    init(initialToken: Wallet) {
        token = initialToken
        tokenName = initialToken.token.name
        super.init()

        $token
            .sink { [weak self] value in
                guard let self = self else { return }
                self.amountText = value.amount?.toString(maximumFractionDigits: Int(value.token.decimals), roundingMode: .down) ?? ""
                self.amountCurrency = value.token.symbol
                self.amountInCurrentFiat = value.amountInCurrentFiat.fiatAmountFormattedString(roundingMode: .down)
                self.tokenName = value.token.name
            }
            .store(in: &subscriptions)
    }
}
