//
//  TokenSettings.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import Foundation

enum TokenSettings: ListItemType {
//    case rename
    case visibility(Bool)
    case close
    case placeholder(Int)
    
    static func placeholder(at index: Int) -> TokenSettings {
        .placeholder(index)
    }
    
    var id: String {
        switch self {
        case .visibility(let isVisible):
            return "visibility:\(isVisible)"
        case .close:
            return "close"
        case .placeholder(let index):
            return "placeholder:\(index)"
        }
    }
}
