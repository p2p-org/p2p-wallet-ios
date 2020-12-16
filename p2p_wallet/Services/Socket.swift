//
//  Socket.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/12/2020.
//

import Foundation

extension SolanaSDK.Socket {
    static var shared = SolanaSDK.Socket(endpoint: Defaults.network.endpoint.replacingOccurrences(of: "http", with: "ws"), publicKey: SolanaSDK.shared.accountStorage.account?.publicKey)
}
