//
//  SendTokenRelayMethod.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/02/2022.
//

import Foundation

enum SendTokenRelayMethod: Int {
    case relay = 0, compensation = 1
    static var `default`: Self {
        .compensation // TODO: default is compensation, as relay is not ready, replace later
    }
}
