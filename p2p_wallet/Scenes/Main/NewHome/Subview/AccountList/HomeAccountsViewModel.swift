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
    private var notificationService: NotificationService

    // MARK: - Properties

    let navigation: PassthroughSubject<HomeNavigation, Never>

    @Published private(set) var balance: String = ""
    @Published private(set) var actions: [WalletActionType] = []
    @Published private(set) var scrollOnTheTop = true
    @Published private(set) var hideZeroBalance: Bool = Defaults.hideZeroBalances

    /// Solana accounts.
    @Published private(set) var solanaAccountsState: AsyncValueState<[RendableSolanaAccount]> = .init(value: [])
    @Published private(set) var ethereumAccountsState: AsyncValueState<[RendableEthereumAccount]> = .init(value: [])

    /// Primary list accounts.
    var accounts: [any RendableAccount] {
        ethereumAccountsState.value
            .filter { account in
                if available(.ethAddressEnabled) {
                    if account.isClaiming || account.onClaim != nil {
                        return true
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
                    if account.isClaiming || account.onClaim != nil {
                        return false
                    }
                }
                return true
            }
            + solanaAccountsState.value.filter { rendableAccount in
                Self.shouldInIgnoreSection(rendableAccount: rendableAccount, hideZeroBalance: hideZeroBalance)
            }
    }

    // MARK: - Initializer

    init(
        solanaAccountsService: SolanaAccountsService = Resolver.resolve(),
        ethereumAccountsService: EthereumAccountsService = Resolver.resolve(),
        wormholeService: WormholeService = Resolver.resolve(),
        favouriteAccountsStore: FavouriteAccountsDataSource = Resolver.resolve(),
        solanaTracker _: SolanaTracker = Resolver.resolve(),
        notificationService: NotificationService = Resolver.resolve(),
        sellDataService: any SellDataService = Resolver.resolve(),
        navigation: PassthroughSubject<HomeNavigation, Never>
    ) {
        self.navigation = navigation
        self.solanaAccountsService = solanaAccountsService
        self.ethereumAccountsService = ethereumAccountsService
        self.notificationService = notificationService

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
            .combineLatest(wormholeService.wormholeClaimMonitoreService.$bundles)
            .map { accounts, bundles in
                // Aggregate accounts with bundle status
                AsyncValueState(
                    status: AsynValueStatus.combine([accounts.status, bundles.status]),
                    value: EthereumAccountsDataSource.aggregate(
                        accounts: accounts.value,
                        wormholeBundlesStatus: bundles.value
                    ),
                    error: accounts.error ?? bundles.error
                )
            }
            .map { accounts in
                accounts.innerApply { account in
                    let isClaiming = account.wormholeBundle?.status == .pending || account.wormholeBundle?
                        .status == .inProgress

                    let balanceInFiat = account.account.balanceInFiat ?? .init(
                        value: 0,
                        currencyCode: Defaults.fiat.rawValue
                    )

                    let isClaimable = !(account.wormholeBundle?.status == .pending || account.wormholeBundle?
                        .status == .inProgress)
                        && balanceInFiat >= CurrencyAmount(usd: 1)

                    return RendableEthereumAccount(
                        account: account.account,
                        isClaiming: isClaiming,
                        onTap: nil,
                        onClaim: isClaimable ? {
                            navigation.send(.claim(account.account))
                        } : nil
                    )
                }
            }
            .receive(on: RunLoop.main)
            .weakAssign(to: \.ethereumAccountsState, on: self)
            .store(in: &subscriptions)

        ethereumAccountsService
            .$state
            .map(\.status)
            .filter { $0 == .fetching }
            .removeDuplicates()
            .sink { _ in
                wormholeService.wormholeClaimMonitoreService.refresh()
            }
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
    }

    func refresh() async throws {
        _ = try await solanaAccountsService.fetch()
        if available(.ethAddressEnabled) {
            _ = try await ethereumAccountsService.fetch()
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
