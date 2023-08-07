import AnalyticsManager
import BigDecimal
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import Sell
import SolanaSwift
import SwiftyUserDefaults
import Web3
import Wormhole

final class HomeAccountsViewModel: BaseViewModel, ObservableObject {
    private var defaultsDisposables: [DefaultsDisposable] = []

    // MARK: - Dependencies

    private let solanaAccountsService: SolanaAccountsService

    private let favouriteAccountsStore: FavouriteAccountsDataSource

    @Injected private var analyticsManager: AnalyticsManager

    // MARK: - Properties

    let navigation: PassthroughSubject<HomeNavigation, Never>

    @Published private(set) var balance: String = ""
    @Published private(set) var usdcAmount: String = ""
    @Published private(set) var actions: [HomeAction] = []
    @Published private(set) var scrollOnTheTop = true
    @Published private(set) var hideZeroBalance: Bool = Defaults.hideZeroBalances

    /// Primary list accounts.
    @Published var accounts: [any RenderableAccount] = []

    /// Secondary list accounts. Will be normally hidded and need to be manually action from user to show in view.
    var hiddenAccounts: [any RenderableAccount] = []

    // MARK: - Initializer

    init(
        solanaAccountsService: SolanaAccountsService = Resolver.resolve(),
        ethereumAccountsService: EthereumAccountsService = Resolver.resolve(),
        userActionService: UserActionService = Resolver.resolve(),
        favouriteAccountsStore: FavouriteAccountsDataSource = Resolver.resolve(),
        sellDataService _: any SellDataService = Resolver.resolve(),
        navigation: PassthroughSubject<HomeNavigation, Never>
    ) {
        self.navigation = navigation
        self.solanaAccountsService = solanaAccountsService
        self.favouriteAccountsStore = favouriteAccountsStore

        actions = [.addMoney]

        super.init()

        // TODO: Replace with combine
        defaultsDisposables.append(Defaults.observe(\.hideZeroBalances) { [weak self] change in
            self?.hideZeroBalance = change.newValue ?? false
        })

        // Ethereum accounts
        let ethereumAggregator = HomeEthereumAccountsAggregator()
        let ethereumAccountsPublisher = Publishers
            .CombineLatest(
                ethereumAccountsService.statePublisher,
                userActionService.actions.map { userActions in
                    userActions.compactMap { $0 as? WormholeClaimUserAction }
                }
            )
            .map { state, actions in
                ethereumAggregator.transform(input: (state.value, actions))
            }

        // Solana accounts
        let solanaAggregator = HomeSolanaAccountsAggregator()
        let solanaAccountsPublisher = Publishers
            .CombineLatest4(
                solanaAccountsService.statePublisher,
                favouriteAccountsStore.$favourites,
                favouriteAccountsStore.$ignores,
                $hideZeroBalance
            )
            .map { state, favourites, ignores, hideZeroBalance in
                solanaAggregator.transform(input: (state.value, favourites, ignores, hideZeroBalance))
            }

        let homeAccountsAggregator = HomeAccountsAggregator()
        Publishers
            .CombineLatest(solanaAccountsPublisher, ethereumAccountsPublisher)
            .map { solanaAccounts, ethereumAccounts in
                homeAccountsAggregator.transform(input: (solanaAccounts, ethereumAccounts))
            }
            .receive(on: RunLoop.main)
            .sink { primary, secondary in
                self.accounts = primary
                self.hiddenAccounts = secondary
            }
            .store(in: &subscriptions)

        // Balance
        solanaAccountsService.statePublisher
            .map { (state: AsyncValueState<[SolanaAccountsService.Account]>) -> String in
                let equityValue: CurrencyAmount = state.value
                    .filter { $0.token.keyAppExtensions.isPositionOnWS ?? false }
                    .filter { $0.token.keyAppExtensions.calculationOfFinalBalanceOnWS ?? true }
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

        analyticsManager.log(event: .claimAvailable(claim: available(.ethAddressEnabled)))

        // USDC amount
        solanaAccountsService.statePublisher
            .map { (state: AsyncValueState<[SolanaAccountsService.Account]>) -> String in
                guard let usdcAccount = state.value.first(where: {
                    $0.isUSDC && ($0.token.keyAppExtensions.isPositionOnWS ?? false)
                }) else {
                    return ""
                }

                let cryptoFormatter = CryptoFormatter()
                return cryptoFormatter.string(amount: usdcAccount.cryptoAmount)
            }
            .receive(on: RunLoop.main)
            .assignWeak(to: \.usdcAmount, on: self)
            .store(in: &subscriptions)
    }

    func refresh() async {
        await HomeAccountsSynchronisationService().refresh()
    }

    func invoke(for account: any RenderableAccount, event: Event) {
        switch account {
        case let renderableAccount as RenderableSolanaAccount:
            switch event {
            case .tap:
                navigation.send(.solanaAccount(renderableAccount.account))
            case .visibleToggle:
                let pubkey = renderableAccount.account.address
                let tags = renderableAccount.tags

                if tags.contains(.ignore) {
                    favouriteAccountsStore.markAsFavourite(key: pubkey)
                } else if tags.contains(.favourite) {
                    favouriteAccountsStore.markAsIgnore(key: pubkey)
                } else {
                    favouriteAccountsStore.markAsIgnore(key: pubkey)
                }
            default:
                break
            }

        case let renderableAccount as RenderableEthereumAccount:
            switch event {
            case .extraButtonTap:
                navigation
                    .send(.claim(renderableAccount.account, renderableAccount.userAction))
            default:
                break
            }

        default:
            break
        }
    }

    func actionClicked(_ action: HomeAction) {
        switch action {
        case .addMoney:
            analyticsManager.log(event: .mainScreenAddMoneyClick)
            navigation.send(.addMoney)
        case .withdraw:
            analyticsManager.log(event: .mainScreenWithdrawClick)
        }
    }

    func scrollToTop() {
        scrollOnTheTop = true
    }

    func viewDidAppear() {
        if let balance = Double(balance) {
            analyticsManager.log(event: .userAggregateBalanceBase(amountUsd: balance, currency: Defaults.fiat.code))
            analyticsManager.log(event: .userHasPositiveBalanceBase(state: balance > 0))
        }
    }

    func balanceTapped() {
        analyticsManager.log(event: .mainScreenAmountClick)
    }

    func hiddenTokensTapped() {
        analyticsManager.log(event: .mainScreenHiddenTokens)
    }
}

extension HomeAccountsViewModel {
    enum Event {
        case tap
        case visibleToggle
        case extraButtonTap
    }
}
