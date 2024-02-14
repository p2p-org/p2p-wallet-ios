import Combine
import Foundation

@MainActor
final class SwapSettingsInfoViewModel: BaseViewModel, ObservableObject {
    enum LoadableFee {
        case loading
        case loaded([Fee])
    }

    let image: ImageResource
    let title: String
    let subtitle: String
    let buttonTitle: String

    @Published var loadableFee: LoadableFee = .loaded([])

    // MARK: - Output

    private let closeSubject = PassthroughSubject<Void, Never>()
    var close: AnyPublisher<Void, Never> { closeSubject.eraseToAnyPublisher() }

    // MARK: - Init

    init(strategy: Strategy) {
        switch strategy {
        case .enjoyFreeTransaction:
            image = .startThree
            title = L10n.enjoyFreeTransactions + "!"
            subtitle = L10n.withKeyAppAllTransactionsYouMakeOnTheSolanaNetworkAreFree
            buttonTitle = L10n.gotIt + "👍"
        case .accountCreationFee:
            image = .accountCreationFeeHand
            title = L10n.accountCreationFee
            subtitle = L10n.whenYouTradeTheTokenForTheFirstTimeSolanaChargesAOneTimeFeeForCreatingAnAccount
            buttonTitle = L10n.gotIt + "👍"
        case .minimumReceived:
            image = .minimumReceived
            title = L10n.minimumReceived
            subtitle = L10n.TheMinimumAmountYouWillReceive.ifThePriceSlipsAnyFurtherYourTransactionWillRevert
            buttonTitle = L10n.done + "👍"
        case .liquidityFee:
            image = .liquidityFee
            title = L10n.liquidityFee
            subtitle = L10n.aFeePaidToTheLiquidityProviders
            buttonTitle = L10n.okay + "👍"
        case .transferFee:
            image = .accountCreationFeeHand
            title = L10n.token2022TransferFee
            subtitle = L10n.ChargeThatYouNeedToPayToSendOrReceiveTokens2022
                .itHelpsMaintainTheNetworkAndEnsureSmoothTransactions
            buttonTitle = L10n.gotIt + "👍"
        }
    }

    func closeClicked() {
        closeSubject.send()
    }
}

// MARK: - Strategy

extension SwapSettingsInfoViewModel {
    enum Strategy {
        case enjoyFreeTransaction
        case accountCreationFee
        case minimumReceived
        case liquidityFee
        case transferFee
    }
}

// MARK: - Fee Model

extension SwapSettingsInfoViewModel {
    struct Fee {
        let title: String
        let subtitle: String
        var amount: String?
    }
}
