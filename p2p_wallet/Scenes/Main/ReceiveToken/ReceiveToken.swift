//
//  ReceiveToken.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/06/2021.
//

import Foundation

struct ReceiveToken {
    enum NavigatableScene {
        case showInExplorer(address: String)
        case share(address: String)
        case help
    }
}
