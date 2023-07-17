//
//  CryptoAccountsViewModel.swift
//  p2p_wallet
//
//  Created by Zafar Ivaev on 13/07/23.
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
import Web3
import Wormhole

/// ViewModel of `CryptoAccounts` scene
final class CryptoAccountsViewModel: BaseViewModel, ObservableObject {
    
    // MARK: - Properties
    
    private let solanaAccountsService: SolanaAccountsService
    private let ethereumAccountsService: EthereumAccountsService
    private let userActionService: UserActionService
    
    private let favouriteAccountsStore: FavouriteAccountsDataSource
    
    private let navigation: PassthroughSubject<CryptoNavigation, Never>
    
    @Published private(set) var scrollOnTheTop = true
    @Published private(set) var hideZeroBalance: Bool = Defaults.hideZeroBalances
    
    /// Primary list accounts.
    @Published var accounts: [any RenderableAccount] = []
    
    /// Secondary list accounts. Will be normally hidden and require manuall action from user to be shown.
    var hiddenAccounts: [any RenderableAccount] = []
    
    /// Accounts for claiming transfers.
    var transferAccounts: [any RenderableAccount] = []
    
    // MARK: - Initialization
    
    init(
        solanaAccountsService: SolanaAccountsService = Resolver.resolve(),
        ethereumAccountsService: EthereumAccountsService = Resolver.resolve(),
        userActionService: UserActionService = Resolver.resolve(),
        favouriteAccountsStore: FavouriteAccountsDataSource = Resolver.resolve(),
        navigation: PassthroughSubject<CryptoNavigation, Never>
    ) {
        self.solanaAccountsService = solanaAccountsService
        self.ethereumAccountsService = ethereumAccountsService
        self.userActionService = userActionService
        self.favouriteAccountsStore = favouriteAccountsStore
        self.navigation = navigation
        
        super.init()
        
        self.bindAccounts()
    }
    
    // MARK: - Binding
    
    private func bindAccounts() {
        // Ethereum accounts
        let ethereumAggregator = CryptoEthereumAccountsAggregator()
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
        let solanaAggregator = CryptoSolanaAccountsAggregator()
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

        let homeAccountsAggregator = CryptoAccountsAggregator()
        Publishers
            .CombineLatest(solanaAccountsPublisher, ethereumAccountsPublisher)
            .map { solanaAccounts, ethereumAccounts in
                homeAccountsAggregator.transform(input: (solanaAccounts, ethereumAccounts))
            }
            .receive(on: RunLoop.main)
            .sink { primary, secondary, transfer in
                self.accounts = primary
                self.hiddenAccounts = secondary
                self.transferAccounts = transfer
            }
            .store(in: &subscriptions)
    }
    
    // MARK: - Actions
    
    func refresh() async {
        await HomeAccountsSynchronisationService().refresh()
    }
    
    func scrollToTop() {
        scrollOnTheTop = true
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
                navigation.send(.claim(renderableAccount.account, renderableAccount.userAction))
            default:
                break
            }

        default:
            break
        }
    }
}

extension CryptoAccountsViewModel {
    enum Event {
        case tap
        case visibleToggle
        case extraButtonTap
    }
}
