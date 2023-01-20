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

    let feeInFiat: Double

    init(feeToken: Wallet, feeInToken: FeeAmount, availableFeeTokens: [Wallet]) {
        title = L10n.thisAddressDoesnTHaveAnAccountForThisToken
        let priceService = Resolver.resolve(PricesServiceType.self)
        let price = priceService.currentPrice(for: feeToken.token.symbol)
        let feeInFiat = (feeInToken.accountBalances.convertToBalance(decimals: feeToken.token.decimals) * price?.value)
        self.feeInFiat = feeInFiat
        let fiatAmount = feeInFiat.fiatAmountFormattedString(roundingMode: .down, customFormattForLessThan1E_2: true)
        description = L10n.youWillHaveToPayAOneTimeFeeToCreateAnAccountForThisAddress(fiatAmount)
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
