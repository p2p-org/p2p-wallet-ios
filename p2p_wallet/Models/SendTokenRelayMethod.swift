//
//  SendTokenRelayMethod.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/02/2022.
//

import Foundation

enum SendTokenRelayMethod: String, CaseIterable {
    case relay, reward
    static var `default`: Self {
        .relay // TODO: default is reward, as relay is not ready, replace later
    }
}
