//
//  NewAnalyticsEvent.swift
//  p2p_wallet
//
//  Created by Ivan on 12.12.2022.
//

import Foundation

// TODO: - [PWN-6939] NewAnalyticsEvent поменяем в AnalyticsEvent
public struct NewAnalyticsEvent {
    let name: String
    let parameters: [String: Any]
    
    init(name: String, parameters: [String: Any] = [:]) {
        self.name = name
        self.parameters = parameters.filter {
            if case Optional<Any>.none = $0.value {
                return false
            } else {
                return true
            }
        }
    }
}
