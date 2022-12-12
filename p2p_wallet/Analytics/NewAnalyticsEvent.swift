//
//  NewAnalyticsEvent.swift
//  p2p_wallet
//
//  Created by Ivan on 12.12.2022.
//

import Foundation

public struct NewAnalyticsEvent {
    let name: String
    let parameters: [String: Any]
    
    init(name: String, parameters: [String: Any] = [:]) {
        self.name = name
        self.parameters = parameters
    }
}
