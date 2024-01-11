import AnalyticsManager
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import Sell
import SolanaSwift

/// ViewModel of `CryptoActionsPanel` scene
final class CryptoActionsPanelViewModel: BaseViewModel, ObservableObject {
    // MARK: - Dependencies

    @Injected var solanaAccountsService: SolanaAccountsService
    @Injected var analyticsManager: AnalyticsManager

    // MARK: - Properties

    @Published private(set) var balance: String = ""
    @Published private(set) var actions: [WalletActionType] = []

    let navigation: PassthroughSubject<CryptoNavigation, Never>

    // MARK: - Initialization

    init(
        sellDataService _: any SellDataService = Resolver.resolve(),
        navigation: PassthroughSubject<CryptoNavigation, Never>
    ) {
        self.navigation = navigation

        super.init()

        actions = [.cashOut, .buy, .receive, .send, .swap]

        bind()
    }

    // MARK: - Binding

    private func bind() {
        solanaAccountsService.statePublisher
            .map { (state: AsyncValueState<[SolanaAccountsService.Account]>) -> String in
                let equityValue: CurrencyAmount = state.value
//                    .filter { !($0.token.keyAppExtensions.isPositionOnWS ?? false) }
                    .reduce(CurrencyAmount(usd: 0)) {
                        $0 + $1.amountInFiat
                    }

                let formatter = CurrencyFormatter(
                    showSpacingAfterCurrencySymbol: false,
                    showSpacingAfterCurrencyGroup: false,
                    showSpacingAfterLessThanOperator: false
                )
                return formatter.string(amount: equityValue)
            }
            .receive(on: RunLoop.main)
            .assignWeak(to: \.balance, on: self)
            .store(in: &subscriptions)
    }

    // MARK: - Actions

    func actionClicked(_ action: WalletActionType) {
        switch action {
        case .buy:
            analyticsManager.log(event: .buyScreenOpened(lastScreen: "mainScreen"))
            navigation.send(.buy)
        case .receive:
            guard let pubkey = try? PublicKey(string: solanaAccountsService.state.value.nativeWallet?.address)
            else { return }
            analyticsManager.log(event: .cryptoReceiveClick)
            navigation.send(.receive(publicKey: pubkey))
        case .send:
            analyticsManager.log(event: .mainScreenSendClick)
            navigation.send(.send)
        case .swap:
            analyticsManager.log(event: .cryptoSwapClick)
            navigation.send(.swap)
        case .cashOut:
            analyticsManager.log(event: .sellClicked(source: "Main"))
            navigation.send(.cashOut)
        }
    }

    func balanceTapped() {
        analyticsManager.log(event: .cryptoAmountClick)
    }

    func viewDidAppear() {
        if let balance = Double(balance) {
            analyticsManager.log(event: .userAggregateBalanceTokens(amountUsd: balance, currency: Defaults.fiat.code))
            analyticsManager.log(event: .userHasPositiveBalanceTokens(state: balance > 0))
        }
    }
}
