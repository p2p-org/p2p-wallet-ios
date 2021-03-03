//
//  HomeItem.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/03/2021.
//

import Foundation

enum HomeItem: Hashable {
    case wallet(Wallet)
    case friend // TODO: - Friend
    
    var wallet: Wallet? {
        switch self {
        case .wallet(let wallet):
            return wallet
        default:
            break
        }
        return nil
    }
}
