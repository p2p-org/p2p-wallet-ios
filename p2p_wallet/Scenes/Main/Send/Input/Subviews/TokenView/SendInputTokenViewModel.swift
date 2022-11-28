import Combine
import SolanaSwift

final class SendInputTokenViewModel: ObservableObject {
    let changeTokenPressed = PassthroughSubject<Void, Never>()

    @Published var token: Wallet

    @Published var amount: Double? = nil
    @Published var amountInCurrentFiat: Double? = nil
    @Published var isTokenChoiceEnabled: Bool = true

    private var subscriptions = Set<AnyCancellable>()

    init() {
        token = Wallet(token: .nativeSolana)

        $token
            .sink { [weak self] value in
                guard let self = self else { return }
                self.amount = value.amount
                self.amountInCurrentFiat = value.amountInCurrentFiat
            }
            .store(in: &subscriptions)
    }
}
