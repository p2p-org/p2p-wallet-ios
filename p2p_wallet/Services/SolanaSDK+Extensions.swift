//
//  SolanaSDK+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import RxSwift

extension SolanaSDK {
    static var shared = SolanaSDK(network: Defaults.network, accountStorage: AccountStorage.shared)
}

extension String: ListItemType {
    static func placeholder(at index: Int) -> String {
        "\(index)"
    }
    var id: String {self}
}
