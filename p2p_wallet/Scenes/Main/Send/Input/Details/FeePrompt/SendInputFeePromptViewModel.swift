import Combine
import Resolver
import SolanaSwift

final class SendInputFeePromptViewModel: ObservableObject {

    @Injected private var walletsRepository: WalletsRepository

    let close = PassthroughSubject<Void, Never>()
    let chooseToken = PassthroughSubject<Void, Never>()

    @Published var title = ""
    @Published var description = ""
    @Published var isChooseTokenAvailable = false
    @Published var continueTitle = ""

    init(currentToken: Token, feeToken: Token) {
        title = L10n.thisAddressDoesNotHaveAAccount(currentToken.symbol)
        description = L10n.YouWillHaveToPayAOneTimeFee0._03ToCreateAAccountForThisAddress(currentToken.symbol)
        continueTitle = L10n.continueWith(feeToken.symbol)

        if walletsRepository.getWallets().count > 1 {
            description = [L10n.YouWillHaveToPayAOneTimeFee0._03ToCreateAAccountForThisAddress(currentToken.symbol), L10n.youCanChooseInWhichCurrencyToPayWithBelow].joined(separator: ". ")
            isChooseTokenAvailable = true
        }
    }
}
