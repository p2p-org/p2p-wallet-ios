import Combine
import Resolver
import SolanaSwift

final class SendInputFeePromptViewModel: ObservableObject {

    let close = PassthroughSubject<Void, Never>()
    let chooseToken = PassthroughSubject<Void, Never>()

    @Published var title = ""
    @Published var description = ""
    @Published var isChooseTokenAvailable = false
    @Published var continueTitle = ""

    init(feeToken: Token, availableFeeTokens: [Wallet]) {
        title = L10n.thisAddressDoesnTHaveAnAccountForThisToken
        description = L10n.YouWillHaveToPayAOneTimeFee0._03ToCreateAnAccountForThisAddress
        continueTitle = L10n.continueWith(feeToken.symbol)

        if availableFeeTokens.count > 1 {
            description.append(". \(L10n.youCanChooseInWhichCurrencyToPayWithBelow)")
            isChooseTokenAvailable = true
        }
    }
}
