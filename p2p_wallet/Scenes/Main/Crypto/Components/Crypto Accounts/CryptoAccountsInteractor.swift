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

protocol CryptoAccountsInteractorProtocol {
    var transferAccountsPublisher: AnyPublisher<[any RenderableAccount], Never> { get }
    var primaryAccountsPublisher: AnyPublisher<[any RenderableAccount], Never> { get }
    var hiddenAccountsPublisher: AnyPublisher<[any RenderableAccount], Never> { get }
    var zeroBalanceTogglePublisher: AnyPublisher<Bool, Never> { get }
    
    func refreshServices() async
    func updateFavorites(renderableAccount: RenderableSolanaAccount)
}

final class CryptoAccountsInteractor: CryptoAccountsInteractorProtocol {
    
    // MARK: - Dependencies
    
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var solanaAccountsService: SolanaAccountsService
    @Injected private var ethereumAccountsService: EthereumAccountsService
    @Injected private var userActionService: UserActionService
    @Injected private var favouriteAccountsStore: FavouriteAccountsDataSource
    
    // MARK: - Initialization
    
    init() {
        bindZeroBalanceToggle()
        bindAccounts()
    }
    
    // MARK: - Properties
    
    private let cryptoAccountsAggregator = CryptoAccountsAggregator()
    
    private var subscriptions = Set<AnyCancellable>()
    private var defaultsDisposables: [DefaultsDisposable] = []
    
    private var _transferAccountsPublisher = CurrentValueSubject<[any RenderableAccount], Never>([])
    private var _primaryAccountsPublisher = CurrentValueSubject<[any RenderableAccount], Never>([])
    private var _hiddenAccountsPublisher = CurrentValueSubject<[any RenderableAccount], Never>([])
    
    private var _zeroBalanceTogglePublisher = CurrentValueSubject<Bool, Never>(Defaults.hideZeroBalances)
    
    private lazy var ethereumAccountsPublisher = Publishers
        .CombineLatest(
            ethereumAccountsService.statePublisher,
            userActionService.actions.map { userActions in
                userActions.compactMap { $0 as? WormholeClaimUserAction }
            }
        )
        .map { state, actions in
            CryptoEthereumAccountsAggregator().transform(input: (state.value, actions))
        }
    
    private lazy var solanaAccountsPublisher = Publishers
        .CombineLatest4(
            solanaAccountsService.statePublisher,
            favouriteAccountsStore.$favourites,
            favouriteAccountsStore.$ignores,
            zeroBalanceTogglePublisher
        )
        .map { state, favourites, ignores, hideZeroBalance in
            CryptoSolanaAccountsAggregator().transform(input: (state.value, favourites, ignores, hideZeroBalance))
        }
    
    // MARK: - Binding
    
    private func bindZeroBalanceToggle() {
        defaultsDisposables.append(Defaults.observe(\.hideZeroBalances) { [weak self] change in
            self?._zeroBalanceTogglePublisher.send(change.newValue ?? false)
        })
    }
    
    private func bindAccounts() {
        Publishers
            .CombineLatest(solanaAccountsPublisher, ethereumAccountsPublisher)
            .map { solanaAccounts, ethereumAccounts in
                CryptoAccountsAggregator().transform(input: (solanaAccounts, ethereumAccounts))
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] transfers, primary, hidden in

                self?._transferAccountsPublisher.send(transfers)
                self?._primaryAccountsPublisher.send(primary)
                self?._hiddenAccountsPublisher.send(hidden)

                self?.analyticsManager.log(event: .cryptoClaimTransferredViewed(claimCount: transfers.count))
            }
            .store(in: &subscriptions)
    }
    
    // MARK: - Protocol Requirements
    
    var transferAccountsPublisher: AnyPublisher<[any RenderableAccount], Never> {
        _transferAccountsPublisher.eraseToAnyPublisher()
    }
    var primaryAccountsPublisher: AnyPublisher<[any RenderableAccount], Never> {
        _primaryAccountsPublisher.eraseToAnyPublisher()
    }
    var hiddenAccountsPublisher: AnyPublisher<[any RenderableAccount], Never> {
        _hiddenAccountsPublisher.eraseToAnyPublisher()
    }
    var zeroBalanceTogglePublisher: AnyPublisher<Bool, Never> {
        _zeroBalanceTogglePublisher.eraseToAnyPublisher()
    }
    
    func refreshServices() async {
        await CryptoAccountsSynchronizationService().refresh()
    }
    
    func updateFavorites(renderableAccount: RenderableSolanaAccount) {
        let pubkey = renderableAccount.account.address
        let tags = renderableAccount.tags

        if tags.contains(.ignore) {
            favouriteAccountsStore.markAsFavourite(key: pubkey)
        } else if tags.contains(.favourite) {
            favouriteAccountsStore.markAsIgnore(key: pubkey)
        } else {
            favouriteAccountsStore.markAsIgnore(key: pubkey)
        }
    }
}
