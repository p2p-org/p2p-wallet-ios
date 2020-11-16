//
//  FetcherState.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/4/20.
//

import Foundation
enum FetcherState<T: Hashable>: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.initializing, .initializing), (.loading, .loading):
            return true
        case (.error(let error1), .error(let error2)):
            return error1.localizedDescription == error2.localizedDescription
        case (.loaded(let data1), .loaded(let data2)):
            return data1 == data2
        default:
            return false
        }
    }
    
    case initializing
    case loading
    case loaded(T)
    case error(Error)
    
    var lastError: Error? {
        switch self {
        case .error(let error):
            return error
        default:
            return nil
        }
    }
}
