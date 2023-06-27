//
//  WalletsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift

enum BEFetcherState {
    case initializing
    case loading
    case loaded
    case error
}

@available(*, deprecated, message: "Use SolanaAccountsService")
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

@available(*, deprecated, message: "Use SolanaAccountsService")
class WalletsRepositoryImpl: NSObject, WalletsRepository {
    private var subscriptions = [AnyCancellable]()
    private let solanaAccountsService: SolanaAccountsService

    init(
        solanaAccountsService: SolanaAccountsService = Resolver.resolve(),
        pricesService: PricesService = Resolver.resolve()
    ) {
        self.solanaAccountsService = solanaAccountsService

        super.init()

        solanaAccountsService
            .statePublisher
            .sink { state in
                // Updating old prices service
                let tokens = state.value.map(\.data.token)
                pricesService.addToWatchList(tokens)
            }
            .store(in: &subscriptions)
    }

    var nativeWallet: SolanaSwift.Wallet? {
        solanaAccountsService.state.value.nativeWallet?.data
    }

    func getWallets() -> [SolanaSwift.Wallet] {
        solanaAccountsService.state.value.map(\.data)
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
        solanaAccountsService
            .statePublisher
            .map { state in
                Self.stateMapping(status: state.status, error: state.error)
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var state: BEFetcherState {
        Self.stateMapping(status: solanaAccountsService.state.status, error: solanaAccountsService.state.error)
    }

    var dataDidChange: AnyPublisher<Void, Never> {
        solanaAccountsService
            .statePublisher
            .map(\.value)
            .removeDuplicates()
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    var dataPublisher: AnyPublisher<[SolanaSwift.Wallet], Never> {
        solanaAccountsService
            .statePublisher
            .map { state in state.value.map(\.data) }
            .eraseToAnyPublisher()
    }

    func getError() -> Swift.Error? {
        solanaAccountsService.state.error
    }

    func reload() {
        Task { try await solanaAccountsService.fetch() }
    }

    func refresh() {
        Task { try await solanaAccountsService.fetch() }
    }
}
