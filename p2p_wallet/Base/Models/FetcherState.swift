//
//  FetcherState.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/4/20.
//

import Foundation
enum FetcherState: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.initializing, .initializing), (.loading, .loading), (.loaded, .loaded):
            return true
        case (.error(let error1), .error(let error2)):
            return error1.localizedDescription == error2.localizedDescription
        default:
            return false
        }
    }
    
    case initializing
    case loading
    case loaded
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
