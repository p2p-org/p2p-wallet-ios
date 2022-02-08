//
//  SendTokenRelayMethod.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/02/2022.
//

import Foundation

enum SendTokenRelayMethod: Int, CaseIterable {
    case relay = 0, reward = 1
    static var `default`: Self {
        .reward // TODO: default is reward, as relay is not ready, replace later
    }
}
