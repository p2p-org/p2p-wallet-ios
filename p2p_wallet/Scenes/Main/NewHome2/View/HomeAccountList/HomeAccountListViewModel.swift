//
//  HomeAccountsList.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 26.06.2023.
//

import Foundation

import Combine
import KeyAppBusiness
import KeyAppKitCore
import Resolver

@MainActor
class HomeAccountListViewModel: BaseViewModel, ObservableObject {
    enum Event {
        case tap
        case visibleToggle
        case extraButtonTap
    }

    // Service
    private let favouriteAccountsStore: FavouriteAccountsDataSource

    /// Hide zero balance accounts
    @Published private(set) var hideZeroBalance: Bool = Defaults.hideZeroBalances

    /// Primary list accounts.
    @Published var accounts: [any RenderableAccount] = []

    /// Secondary list accounts. Will be normally hidded and need to be manually action from user to show in view.
    @Published var hiddenAccounts: [any RenderableAccount] = []

    init(
        solanaAccountsService: SolanaAccountsService = Resolver.resolve(),
        favouriteAccountsStore: FavouriteAccountsDataSource = Resolver.resolve()
    ) {
        self.favouriteAccountsStore = favouriteAccountsStore

        super.init()

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
        solanaAccountsPublisher
            .map { solanaAccounts in
                homeAccountsAggregator.transform(input: (solanaAccounts, []))
            }
            .receive(on: RunLoop.main)
            .sink { primary, secondary in
                self.accounts = primary
                self.hiddenAccounts = secondary
            }
            .store(in: &subscriptions)
    }

    func invoke(for _: any RenderableAccount, event _: Event) {
//        switch account {
//        case let renderableAccount as RenderableSolanaAccount:
//            switch event {
//            case .tap:
//                navigation.send(.solanaAccount(renderableAccount.account))
//            case .visibleToggle:
//                guard let pubkey = renderableAccount.account.data.pubkey else { return }
//                let tags = renderableAccount.tags
//
//                if tags.contains(.ignore) {
//                    favouriteAccountsStore.markAsFavourite(key: pubkey)
//                } else if tags.contains(.favourite) {
//                    favouriteAccountsStore.markAsIgnore(key: pubkey)
//                } else {
//                    favouriteAccountsStore.markAsIgnore(key: pubkey)
//                }
//            default:
//                break
//            }
//
//        case let renderableAccount as RenderableEthereumAccount:
//            switch event {
//            case .extraButtonTap:
//                navigation.send(.claim(renderableAccount.account, renderableAccount.userAction as?
//                WormholeClaimUserAction))
//            default:
//                break
//            }
//
//        default:
//            break
//        }
    }
}

