import Combine
import SolanaSwift

final class SendInputTokenViewModel: BaseViewModel, ObservableObject {
    let changeTokenPressed = PassthroughSubject<Void, Never>()

    @Published var token: Wallet

    @Published var amount: Double? = nil
    @Published var amountInCurrentFiat: Double? = nil
    @Published var isTokenChoiceEnabled: Bool = true

    init(initialToken: Wallet) {
        token = initialToken
        super.init()

        $token
            .sink { [weak self] value in
                guard let self = self else { return }
                self.amount = value.amount
                self.amountInCurrentFiat = value.amountInCurrentFiat
            }
            .store(in: &subscriptions)
    }
}
