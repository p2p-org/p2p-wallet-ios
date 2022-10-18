//
//  RemoteConfig+Extensions.swift
//  p2p_wallet
//
//  Created by Ivan on 10.06.2022.
//

import FirebaseRemoteConfig
import SolanaSwift

extension RemoteConfig {
    func configValues<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        let jsonData = configValue(forKey: key).dataValue
        let decoded = try? JSONDecoder().decode(type, from: jsonData)
        return decoded
    }
}

// MARK: - Defined Endpoints

extension RemoteConfig {
    var definedEndpoints: [NetworkValue] {
        configValues([NetworkValue].self, forKey: "settings_network_values") ?? []
    }

    struct NetworkValue: Codable {
        let urlString: String?
        let network: Network?
        let additionalQuery: String?
    }
}

// MARK: - Solana Status

extension RemoteConfig {
    var solanaNegativeStatusFrequency: String? {
        configValue(forKey: "solana_negative_status_frequency").stringValue
    }

    var solanaNegativeStatusPercent: Int? {
        configValues(Int.self, forKey: "solana_negative_status_percent")
    }

    var solanaNegativeStatusTimeFrequency: Int? {
        configValues(Int.self, forKey: "solana_negative_status_time_frequency")
    }
}
