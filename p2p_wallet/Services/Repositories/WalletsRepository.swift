//
//  WalletsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import BECollectionView_Core
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift

@available(*, deprecated, message: "Use AccountsService")
protocol WalletsRepository {
    var nativeWallet: Wallet? { get }

    func getWallets() -> [Wallet]

    var statePublisher: AnyPublisher<BEFetcherState, Never> { get }
    var dataDidChange: AnyPublisher<Void, Never> { get }
    var dataPublisher: AnyPublisher<[Wallet], Never> { get }

    func getError() -> Error?

    func reload()
    func refresh()

    var state: BEFetcherState { get }
}

@available(*, deprecated, message: "Use AccountsService")
class WalletsRepositoryImpl: NSObject, WalletsRepository {
    private var subscriptions = [AnyCancellable]()
    private let accountsService: AccountsService

    init(
        accountsService: AccountsService = Resolver.resolve(),
        pricesService: PricesService = Resolver.resolve()
    ) {
        self.accountsService = accountsService

        super.init()

        accountsService
            .solanaAccountsStatePublisher
            .sink { state in
                // Updating old prices service
                let tokens = state.value.map(\.data.token)
                pricesService.addToWatchList(tokens)
            }
            .store(in: &subscriptions)
    }

    var nativeWallet: SolanaSwift.Wallet? {
        accountsService.solanaAccountsState.value.nativeWallet?.data
    }

    func getWallets() -> [SolanaSwift.Wallet] {
        accountsService.solanaAccountsState.value.map(\.data)
    }

    static func stateMapping(status: AsynValueStatus, error: Swift.Error?) -> BEFetcherState {
        if error != nil {
            return BEFetcherState.error
        }

        switch status {
        case .initializing:
            return BEFetcherState.initializing
        case .fetching:
            return BEFetcherState.loading
        case .ready:
            return BEFetcherState.loaded
        }
    }

    var statePublisher: AnyPublisher<BEFetcherState, Never> {
        accountsService
            .solanaAccountsStatePublisher
            .map { state in
                Self.stateMapping(status: state.status, error: state.error)
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var state: BEFetcherState {
        Self.stateMapping(
            status: accountsService.solanaAccountsState.status,
            error: accountsService.solanaAccountsState.error
        )
    }

    var dataDidChange: AnyPublisher<Void, Never> {
        accountsService
            .solanaAccountsStatePublisher
            .map(\.value)
            .removeDuplicates()
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    var dataPublisher: AnyPublisher<[SolanaSwift.Wallet], Never> {
        accountsService
            .solanaAccountsStatePublisher
            .map { state in state.value.map(\.data) }
            .eraseToAnyPublisher()
    }

    func getError() -> Swift.Error? {
        accountsService.solanaAccountsState.error
    }

    func reload() {
        Task { try await accountsService.reloadSolanaAccounts() }
    }

    func refresh() {
        Task { try await accountsService.reloadSolanaAccounts() }
    }
}
