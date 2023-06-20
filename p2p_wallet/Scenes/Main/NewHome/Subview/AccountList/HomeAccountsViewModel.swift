import AnalyticsManager
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
import BankTransfer

final class HomeAccountsViewModel: BaseViewModel, ObservableObject {
    private var defaultsDisposables: [DefaultsDisposable] = []

    // MARK: - Dependencies

    private let solanaAccountsService: SolanaAccountsService
    private let ethereumAccountsService: EthereumAccountsService

    private let favouriteAccountsStore: FavouriteAccountsDataSource

    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var bankTransferService: BankTransferService

    // MARK: - Properties

    let navigation: PassthroughSubject<HomeNavigation, Never>

    @Published private(set) var balance: String = ""
    @Published private(set) var actions: [WalletActionType] = []
    @Published private(set) var scrollOnTheTop = true
    @Published private(set) var hideZeroBalance: Bool = Defaults.hideZeroBalances
    @Published private(set) var smallBanner: HomeBannerParameters?
    @Published private(set) var bannerTapped: Bool = false

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
        sellDataService: any SellDataService = Resolver.resolve(),
        navigation: PassthroughSubject<HomeNavigation, Never>
    ) {
        self.navigation = navigation
        self.solanaAccountsService = solanaAccountsService
        self.ethereumAccountsService = ethereumAccountsService
        self.favouriteAccountsStore = favouriteAccountsStore

        var actions: [WalletActionType] = [.topUp]
        if sellDataService.isAvailable {
            actions.append(.cashOut)
        }
        actions.append(.send)
        self.actions = actions

        super.init()
        bindTransferData()

        // TODO: Replace with combine
        defaultsDisposables.append(Defaults.observe(\.hideZeroBalances) { [weak self] change in
            self?.hideZeroBalance = change.newValue ?? false
        })

        // Ethereum accounts
        let ethereumAggregator = HomeEthereumAccountsAggregator()
        let ethereumAccountsPublisher = Publishers
            .CombineLatest(
                ethereumAccountsService.statePublisher,
                userActionService.$actions.map { userActions in
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
                let equityValue: Double = state.value.reduce(0) { $0 + $1.amountInFiatDouble }
                return "\(Defaults.fiat.symbol) \(equityValue.toString(maximumFractionDigits: 2))"
            }
            .receive(on: RunLoop.main)
            .assignWeak(to: \.balance, on: self)
            .store(in: &subscriptions)

        analyticsManager.log(event: .claimAvailable(claim: available(.ethAddressEnabled)))
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
                guard let pubkey = renderableAccount.account.data.pubkey else { return }
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
                navigation.send(.claim(renderableAccount.account, renderableAccount.userAction as? WormholeClaimUserAction))
            default:
                break
            }

        default:
            break
        }
    }

    func actionClicked(_ action: WalletActionType) {
        switch action {
        case .receive:
            guard let pubkey = try? PublicKey(string: solanaAccountsService.state.value.nativeWallet?.data.pubkey)
            else { return }
            navigation.send(.receive(publicKey: pubkey))
        case .buy:
            navigation.send(.buy)
        case .send:
            navigation.send(.send)
        case .swap:
            navigation.send(.swap)
        case .cashOut:
            navigation.send(.cashOut)
        case .topUp:
            navigation.send(.topUp)
        }
    }

    func earn() {
        navigation.send(.earn)
    }

    func scrollToTop() {
        scrollOnTheTop = true
    }

    func sellTapped() {
        navigation.send(.cashOut)
    }

    func closeBanner() {
        smallBanner = nil
        bannerTapped = false
    }
}

extension HomeAccountsViewModel {
    enum Event {
        case tap
        case visibleToggle
        case extraButtonTap
    }
}

private extension HomeAccountsViewModel {
    func bindTransferData() {
        bankTransferService.state
            .filter({ $0.value.userId != nil && $0.value.mobileVerified })
            .map { value in
                HomeBannerParameters(status: value.value.kycStatus, action: { [weak self] in
                    self?.navigation.send(.bankTransfer)
                    self?.bannerTapped = true
                }, isSmallBanner: true)
            }
            .assignWeak(to: \.smallBanner, on: self)
            .store(in: &subscriptions)
    }
}
