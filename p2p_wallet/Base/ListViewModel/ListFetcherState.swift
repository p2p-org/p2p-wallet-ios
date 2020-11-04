//
//  ListFetcherState.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/4/20.
//

import Foundation
enum ListFetcherState: Equatable {
    static func == (lhs: ListFetcherState, rhs: ListFetcherState) -> Bool {
        switch (lhs, rhs) {
        case (.loading(let loading1), .loading(let loading2)):
            return loading1 == loading2
        case (.listEnded, .listEnded):
            return true
        case (.error(let error1), .error(let error2)):
            return error1.localizedDescription == error2.localizedDescription
        case (.listEmpty, .listEmpty):
            return true
        default:
            return false
        }
    }
    
    case loading(Bool)
    case listEnded
    case listEmpty
    case error(error: Error)
    
    var lastError: Error? {
        switch self {
        case .error(let error):
            return error
        default:
            return nil
        }
    }
}
