import Combine
import Resolver
final class SendInputFeePromptViewModel: ObservableObject {

    @Injected private var walletsRepository: WalletsRepository

    let close = PassthroughSubject<Void, Never>()
    let chooseToken = PassthroughSubject<Void, Never>()

    @Published var title: String = L10n.thisAddressDoesNotHaveAUSDCAccount
    @Published var description: String = L10n.YouWillHaveToPayAOneTimeFee0._03ToCreateAUSDCAccountForThisAddress

    @Published var isChooseTokenAvailable: Bool = false

    init() {
        if walletsRepository.getWallets().count > 1 {
            description = [L10n.YouWillHaveToPayAOneTimeFee0._03ToCreateAUSDCAccountForThisAddress, L10n.youCanChooseInWhichCurrencyToPayWithBelow].joined(separator: ". ")
            isChooseTokenAvailable = true
        }
    }
}
