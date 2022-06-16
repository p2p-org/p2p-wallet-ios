//
//  RemoteConfig+Extensions.swift
//  p2p_wallet
//
//  Created by Ivan on 10.06.2022.
//

import FirebaseRemoteConfig
import OrcaSwapSwift

extension RemoteConfig {
    var definedEndpoints: [NetworkValue] {
        let jsonData = configValue(forKey: "settings_network_values").dataValue
        let decoded = (try? JSONDecoder().decode([NetworkValue].self, from: jsonData)) ?? []
        return decoded
    }

    struct NetworkValue: Codable {
        let urlString: String?
        let network: Network?
        let additionalQuery: String?
    }
}
