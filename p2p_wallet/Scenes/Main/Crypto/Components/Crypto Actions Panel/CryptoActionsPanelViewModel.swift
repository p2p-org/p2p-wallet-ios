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

        actions = [.receive, .swap]

        bind()
    }

    // MARK: - Binding

    private func bind() {
        solanaAccountsService.statePublisher
            .map { (state: AsyncValueState<[SolanaAccountsService.Account]>) -> String in
                let equityValue: CurrencyAmount = state.value
                    .filter { !$0.isUSDC }
                    .reduce(CurrencyAmount(usd: 0)) {
                        if $1.token.keyAppExtensions.ruleOfProcessingTokenPriceWS == .byCountOfTokensValue {
                            return $0 + CurrencyAmount(usd: $1.cryptoAmount.amount)
                        } else {
                            return $0 + $1.amountInFiat
                        }
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
        case .receive:
            guard let pubkey = try? PublicKey(string: solanaAccountsService.state.value.nativeWallet?.address)
            else { return }
            analyticsManager.log(event: .cryptoReceiveClick)
            navigation.send(.receive(publicKey: pubkey))
        case .swap:
            analyticsManager.log(event: .cryptoSwapClick)
            navigation.send(.swap)
        default: break
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
