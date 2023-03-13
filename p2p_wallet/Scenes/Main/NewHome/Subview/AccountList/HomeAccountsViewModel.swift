//
//  HomeWithTokensViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 05.08.2022.
//

import AnalyticsManager
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import Sell
import SolanaSwift
import SwiftyUserDefaults

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
    @Published private(set) var ethereumAccountsState: AsyncValueState<[RendableEthereumAccount]> = .init(value: [])

    /// Primary list accounts.
    var accounts: [any RendableAccount] {
        ethereumAccountsState.value
            + solanaAccountsState.value.filter { rendableAccount in
                Self.shouldInVisiableSection(rendableAccount: rendableAccount, hideZeroBalance: hideZeroBalance)
            }
    }

    /// Secondary list accounts. Will be hidded normally and need to be manually action from user to show in view.
    var hiddenAccounts: [any RendableAccount] {
        solanaAccountsState.value.filter { rendableAccount in
            Self.shouldInIgnoreSection(rendableAccount: rendableAccount, hideZeroBalance: hideZeroBalance)
        }
    }

    // MARK: - Initializer

    init(
        solanaAccountsService: SolanaAccountsService = Resolver.resolve(),
        ethereumAccountsService: EthereumAccountsService = Resolver.resolve(),
        favouriteAccountsStore: FavouriteAccountsStore = Resolver.resolve(),
        solanaTracker: SolanaTracker = Resolver.resolve(),
        notificationService: NotificationService = Resolver.resolve(),
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
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
            .map { state in
                state.innerApply { account in
                    RendableEthereumAccount(account: account) {
                        navigation.send(.claim(account))
                    }
                }
            }
            .weakAssign(to: \.ethereumAccountsState, on: self)
            .store(in: &subscriptions)

        // Solana accounts
        solanaAccountsService.$state
            .map { (state: AsyncValueState<[SolanaAccountsService.Account]>) -> String in
                let equityValue: Double = state.value.reduce(0) { $0 + $1.amountInFiat }
                return "\(Defaults.fiat.symbol) \(equityValue.toString(maximumFractionDigits: 2))"
            }
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
            .weakAssign(to: \.balance, on: self)
            .store(in: &subscriptions)

        solanaAccountsService.$state
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
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
            .weakAssign(to: \.solanaAccountsState, on: self)
            .store(in: &subscriptions)
    }

    func refresh() async throws {
        let _ = try await (
            solanaAccountsService.fetch(),
            ethereumAccountsService.fetch()
        )
    }

    func actionClicked(_ action: WalletActionType) {
        switch action {
        case .receive:
            guard let pubkey = try? PublicKey(string: solanaAccountsService.state.value.nativeWallet?.data.pubkey) else { return }
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
