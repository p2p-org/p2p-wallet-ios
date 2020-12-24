//
//  Settings.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation

extension DefaultsKeys {
    var didSetEnableBiometry: DefaultsKey<Bool> {.init(#function, defaultValue: false)}
    var isBiometryEnabled: DefaultsKey<Bool> {.init(#function, defaultValue: false)}
    var didSetEnableNotifications: DefaultsKey<Bool> {.init(#function, defaultValue: false)}
    var network: DefaultsKey<SolanaSDK.Network> {.init(#function, defaultValue: .mainnetBeta)}
    var walletName: DefaultsKey<[String: String]> {.init(#function, defaultValue: [:])}
}
