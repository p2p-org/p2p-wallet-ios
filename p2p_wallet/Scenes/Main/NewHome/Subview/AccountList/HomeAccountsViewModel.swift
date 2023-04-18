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

final class HomeAccountsViewModel: BaseViewModel, ObservableObject {
    private var defaultsDisposables: [DefaultsDisposable] = []

    // MARK: - Dependencies

    private let solanaAccountsService: SolanaAccountsService
    private let ethereumAccountsService: EthereumAccountsService

    @Injected private var analyticsManager: AnalyticsManager

    // MARK: - Properties

    let navigation: PassthroughSubject<HomeNavigation, Never>

    @Published private(set) var balance: String = ""
    @Published private(set) var actions: [WalletActionType] = []
    @Published private(set) var scrollOnTheTop = true
    @Published private(set) var hideZeroBalance: Bool = Defaults.hideZeroBalances

    /// Solana accounts.
    @Published private(set) var solanaAccountsState: AsyncValueState<[RendableSolanaAccount]> = .init(value: [])
    @Published private(set) var ethereumAccountsState: AsyncValueState<[RenderableEthereumAccount]> = .init(value: [])

    /// Primary list accounts.
    var accounts: [any RendableAccount] {
        ethereumAccountsState.value
            .filter { account in
                if available(.ethAddressEnabled) {
                    if account.isClaiming || account.onClaim != nil {
                        return Self.shouldInVisiableSection(ethereumAcount: account)
                    }
                }
                return false
            }
            + solanaAccountsState.value.filter { rendableAccount in
                Self.shouldInVisiableSection(rendableAccount: rendableAccount, hideZeroBalance: hideZeroBalance)
            }
    }

    /// Secondary list accounts. Will be hidded normally and need to be manually action from user to show in view.
    var hiddenAccounts: [any RendableAccount] {
        ethereumAccountsState.value
            .filter { account in
                if available(.ethAddressEnabled) {
                    return false
                }
                return Self.shouldInIgnoreSection(ethereumAcount: account)
            }
            + solanaAccountsState.value.filter { rendableAccount in
                Self.shouldInIgnoreSection(rendableAccount: rendableAccount, hideZeroBalance: hideZeroBalance)
            }
    }

    // MARK: - Initializer

    init(
        solanaAccountsService: SolanaAccountsService = Resolver.resolve(),
        ethereumAccountsService: EthereumAccountsService = Resolver.resolve(),
        wormholeService _: WormholeService = Resolver.resolve(),
        userActionService: UserActionService = Resolver.resolve(),
        favouriteAccountsStore: FavouriteAccountsDataSource = Resolver.resolve(),
        solanaTracker _: SolanaTracker = Resolver.resolve(),
        notificationService _: NotificationService = Resolver.resolve(),
        sellDataService: any SellDataService = Resolver.resolve(),
        navigation: PassthroughSubject<HomeNavigation, Never>
    ) {
        self.navigation = navigation
        self.solanaAccountsService = solanaAccountsService
        self.ethereumAccountsService = ethereumAccountsService

        if sellDataService.isAvailable {
            actions = [.buy, .receive, .send, .cashOut]
        } else {
            actions = [.buy, .receive, .send]
        }

        super.init()

        // TODO: Replace with combine
        defaultsDisposables.append(Defaults.observe(\.hideZeroBalances) { [weak self] change in
            self?.hideZeroBalance = change.newValue ?? false
        })

        // Listen changing accounts from accounts manager
        // Ethereum accounts
        ethereumAccountsService.$state
            .map { state in
                state.apply { accounts in
                    // Filter accounts by supported Wormhole
                    accounts.filter { account in
                        switch account.token.contractType {
                        case .native:
                            // We always support native token
                            return true
                        case let .erc20(contract):
                            // Check erc-20 tokens
                            return Wormhole.SupportedToken.bridges.contains { bridge in
                                if let bridgeTokenAddress = bridge.ethAddress {
                                    // Supported bridge token is erc-20
                                    return (try? EthereumAddress(hex: bridgeTokenAddress, eip55: false)) == contract
                                } else {
                                    // Supported bridge token is native.
                                    return false
                                }
                            }
                        }
                    }
                }
            }
            .combineLatest(
                userActionService.$actions.map { userActions in
                    userActions.compactMap {
                        $0 as? WormholeClaimUserAction
                    }
                }
            )
            .map { accounts, userActions in
                // Aggregate accounts with bundle status
                AsyncValueState(
                    status: accounts.status,
                    value: EthereumAccountsDataSource.aggregate(
                        accounts: accounts.value,
                        claimUserActions: userActions
                    ),
                    error: accounts.error
                )
            }
            .map { accounts in
                accounts.innerApply { account in
                    let isClaiming = account.isClaiming

                    let balanceInFiat = account.account.balanceInFiat ?? .init(
                        value: 0,
                        currencyCode: Defaults.fiat.rawValue
                    )

                    let isClaimable = !account.isClaiming && balanceInFiat >= CurrencyAmount(usd: 1)

                    return RenderableEthereumAccount(
                        account: account.account,
                        isClaiming: isClaiming,
                        onTap: nil,
                        onClaim: isClaimable ? {
                            navigation.send(.claim(account.account))
                            self.analyticsManager.log(event: .claimBridgesButtonClick)
                        } : nil
                    )
                }
            }
            .receive(on: RunLoop.main)
            .weakAssign(to: \.ethereumAccountsState, on: self)
            .store(in: &subscriptions)

        // Solana accounts
        solanaAccountsService.$state
            .map { (state: AsyncValueState<[SolanaAccountsService.Account]>) -> String in
                let equityValue: Double = state.value.reduce(0) { $0 + $1.amountInFiatDouble }
                return "\(Defaults.fiat.symbol) \(equityValue.toString(maximumFractionDigits: 2))"
            }
            .receive(on: RunLoop.main)
            .weakAssign(to: \.balance, on: self)
            .store(in: &subscriptions)

        solanaAccountsService.$state
            .map { state in
                // Filter NFT
                state.apply { accounts in
                    accounts
                        .filter { !$0.data.isNFTToken }
                        .sorted(by: HomeAccountsViewModel.defaultSolanaAccountsSorter)
                }
            }
            .combineLatest(favouriteAccountsStore.$favourites, favouriteAccountsStore.$ignores)
            .map { state, favourites, ignores in
                // Comfort to rendable protocol
                state.innerApply { account in
                    var tags: AccountTags = []

                    if favourites.contains(account.data.pubkey ?? "") {
                        tags.insert(.favourite)
                    }

                    if ignores.contains(account.data.pubkey ?? "") {
                        tags.insert(.ignore)
                    }

                    return RendableSolanaAccount(
                        account: account,
                        extraAction: .visiable(
                            action: { [weak favouriteAccountsStore] in
                                guard let pubkey = account.data.pubkey else { return }
                                if tags.contains(.ignore) {
                                    favouriteAccountsStore?.markAsFavourite(key: pubkey)
                                } else if tags.contains(.favourite) {
                                    favouriteAccountsStore?.markAsIgnore(key: pubkey)
                                } else {
                                    favouriteAccountsStore?.markAsFavourite(key: pubkey)
                                }
                            }
                        ),
                        tags: tags,
                        onTap: { navigation.send(.solanaAccount(account)) }
                    )
                }
            }
            .receive(on: RunLoop.main)
            .weakAssign(to: \.solanaAccountsState, on: self)
            .store(in: &subscriptions)

        analyticsManager.log(event: .claimAvailable(claim: available(.ethAddressEnabled)))
    }

    func refresh() async throws {
        // use throwing task group to make solanaAccountService.fetch() and ethereumAccountService.fetch() run parallelly
        // and support another chains later
        try await withThrowingTaskGroup(of: Void.self) { group in
            // solana
            group.addTask {
                try await solanaAccountsService.fetch()
            }
            
            // ethereum
            if available(.ethAddressEnabled) {
                group.addTask {
                    try await ethereumAccountsService.fetch()
                }
            }
            
            // another chains goes here
            
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
}
