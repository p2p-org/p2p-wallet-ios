//
//  RemoteConfig+Extensions.swift
//  p2p_wallet
//
//  Created by Ivan on 10.06.2022.
//

import FirebaseRemoteConfig

extension RemoteConfig {
    var definedEndpoints: [String] {
        configValue(forKey: "settings_network_values").jsonValue as? [String] ?? []
    }
}
