//
//  BEFetcherState.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import Foundation

public enum BEFetcherState: Equatable {
    case initializing
    case loading
    case loaded
    case error
}
