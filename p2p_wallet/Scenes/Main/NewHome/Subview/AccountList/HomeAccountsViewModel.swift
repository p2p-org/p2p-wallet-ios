//
//  HomeWithTokensViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 05.08.2022.
//

import AnalyticsManager
import Combine
import Foundation
import Resolver
import Sell
import SolanaSwift
import SwiftyUserDefaults

final class HomeAccountsViewModel: BaseViewModel, ObservableObject {
    private var defaultsDisposables: [DefaultsDisposable] = []

    // MARK: - Dependencies

    private let solanaAccountsManager: SolanaAccountsManager
    @Injected private var analyticsManager: AnalyticsManager

    // MARK: - Properties

    let navigation: PassthroughSubject<HomeNavigation, Never>

    @Published private(set) var balance: String = ""
    @Published private(set) var actions: [WalletActionType] = []
    @Published private(set) var scrollOnTheTop = true
    @Published private(set) var hideZeroBalance: Bool = Defaults.hideZeroBalances

    /// Solana accounts.
    @Published private(set) var solanaAccountsState: AsynValueState<[RendableSolanaAccount]> = .init(item: [])

    /// Primary list accounts.
    var accounts: [any RendableAccount] {
        solanaAccountsState.item.filter { rendableAccount in
            Self.shouldInVisiableSection(rendableAccount: rendableAccount, hideZeroBalance: hideZeroBalance)
        }
    }

    /// Secondary list accounts. Will be hidded normally and need to be manually action from user to show in view.
    var hiddenAccounts: [any RendableAccount] {
        solanaAccountsState.item.filter { rendableAccount in
            Self.shouldInIgnoreSection(rendableAccount: rendableAccount, hideZeroBalance: hideZeroBalance)
        }
    }

    // MARK: - Initializer

    init(
        solanaAccountsManager: SolanaAccountsManager = Resolver.resolve(),
        favouriteAccountsStore: FavouriteAccountsStore = Resolver.resolve(),
        solanaTracker: SolanaTracker = Resolver.resolve(),
        notificationService: NotificationService = Resolver.resolve(),
        sellDataService: any SellDataService = Resolver.resolve(),
        navigation: PassthroughSubject<HomeNavigation, Never>
    ) {
        self.navigation = navigation
        self.solanaAccountsManager = solanaAccountsManager

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

        solanaAccountsManager.$state
            .map { (state: AsynValueState<[SolanaAccountsManager.Account]>) -> String in
                let equityValue: Double = state.item.reduce(0) { $0 + $1.amountInFiat }
                return "\(Defaults.fiat.symbol) \(equityValue.toString(maximumFractionDigits: 2))"
            }
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
            .weakAssign(to: \.balance, on: self)
            .store(in: &subscriptions)

        // Listen changing accounts from accounts manager
        solanaAccountsManager.$state
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

                    print("Tags: ", tags)

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
        try await solanaAccountsManager.fetch()
    }

    func actionClicked(_ action: WalletActionType) {
        switch action {
        case .receive:
            guard let pubkey = try? PublicKey(string: solanaAccountsManager.state.item.nativeWallet?.data.pubkey) else { return }
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

extension Wallet: Identifiable {
    public var id: String {
        return name + pubkey
    }
}

extension Wallet {
    var isNFTToken: Bool {
        // Hide NFT TODO: $0.token.supply == 1 is also a condition for NFT but skipped atm
        token.decimals == 0
    }
}

private extension HomeAccountsViewModel {
    static func shouldInIgnoreSection(rendableAccount: RendableSolanaAccount, hideZeroBalance: Bool) -> Bool {
        if rendableAccount.isInIgnoreList {
            return true
        } else if hideZeroBalance, rendableAccount.account.data.lamports == 0 {
            return true
        } else {
            return false
        }
    }
    
    static func shouldInVisiableSection(rendableAccount: RendableSolanaAccount, hideZeroBalance: Bool) -> Bool {
        if rendableAccount.tags.contains(.favourite) {
            return true
        } else if hideZeroBalance, rendableAccount.account.data.lamports == 0 {
            return false
        } else {
            return true
        }
    }


    static var defaultSolanaAccountsSorter: (SolanaAccountsManager.Account, SolanaAccountsManager.Account) -> Bool {
        { lhs, rhs in
            // prefers non-liquidity token than liquidity tokens
            if lhs.data.token.isLiquidity != rhs.data.token.isLiquidity {
                return !lhs.data.token.isLiquidity
            }

            // prefers prioritized tokens than others
            let prioritizedTokenMints = [
                PublicKey.usdcMint.base58EncodedString,
                PublicKey.usdtMint.base58EncodedString
            ]
            for mint in prioritizedTokenMints {
                if mint == lhs.data.token.address || mint == rhs.data.token.address {
                    return mint == lhs.data.token.address
                }
            }

            // prefers token which more value than the other in fiat
            if lhs.amountInFiat != rhs.amountInFiat {
                return lhs.amountInFiat > rhs.amountInFiat
            }

            // prefers known token than unknown ones
            if lhs.data.token.symbol.isEmpty != rhs.data.token.symbol.isEmpty {
                return !lhs.data.token.symbol.isEmpty
            }

            // prefers token which more balance than the others
            if lhs.data.amount != rhs.data.amount {
                return lhs.data.amount.orZero > rhs.data.amount.orZero
            }

            // sort by symbol
            if lhs.data.token.symbol != rhs.data.token.symbol {
                return lhs.data.token.symbol < rhs.data.token.symbol
            }

            // then name
            return lhs.data.name < rhs.data.name
        }
    }
}
