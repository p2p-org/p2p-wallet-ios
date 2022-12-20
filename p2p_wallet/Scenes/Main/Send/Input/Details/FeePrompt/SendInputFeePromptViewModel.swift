import Combine
import Resolver
import SolanaSwift

final class SendInputFeePromptViewModel: BaseViewModel, ObservableObject {

    let close = PassthroughSubject<Void, Never>()
    let chooseToken = PassthroughSubject<Void, Never>()

    @Published var title: String
    @Published var description: String
    @Published var isChooseTokenAvailable: Bool
    @Published var continueTitle: String
    @Published var feeToken: Wallet

    init(feeToken: Wallet, availableFeeTokens: [Wallet]) {
        title = L10n.thisAddressDoesnTHaveAnAccountForThisToken
        description = L10n.YouWillHaveToPayAOneTimeFee0._03ToCreateAnAccountForThisAddress
        continueTitle = L10n.continueWith(feeToken.token.symbol)
        isChooseTokenAvailable = availableFeeTokens.count > 1
        self.feeToken = feeToken

        super.init()

        if isChooseTokenAvailable {
            description.append(". \(L10n.youCanChooseInWhichCurrencyToPayWithBelow)")
        }

        $feeToken
            .sink { [weak self] value in
                self?.continueTitle = L10n.continueWith(value.token.symbol)
            }
            .store(in: &subscriptions)
    }
}
