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

extension SolanaAccountsService {
    func reload() {
        Task { try await fetch() }
    }
    
    func getWallets() -> [SolanaSwift.Wallet] {
        state.value.map(\.data)
    }
    
    var dataDidChange: AnyPublisher<Void, Never> {
        statePublisher
            .map(\.value)
            .removeDuplicates()
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    var dataPublisher: AnyPublisher<[SolanaSwift.Wallet], Never> {
        statePublisher
            .map { state in state.value.map(\.data) }
            .eraseToAnyPublisher()
    }
    
    var fetcherStatePublisher: AnyPublisher<BEFetcherState, Never> {
        statePublisher
            .map { state in
                Self.stateMapping(status: state.status, error: state.error)
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
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
    
    var fetcherState: BEFetcherState {
        Self.stateMapping(status: state.status, error: state.error)
    }
}
