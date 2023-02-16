//
//  PT.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/12/2021.
//

import Foundation

enum ProcessTransaction {
    enum NavigatableScene {
        case explorer
        case makeAnotherTransaction
        case specificErrorHandler(Swift.Error)
    }
}
