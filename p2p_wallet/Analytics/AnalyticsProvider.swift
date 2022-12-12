//
//  AnalyticsProvider.swift
//  p2p_wallet
//
//  Created by Ivan on 09.12.2022.
//

import Foundation

protocol AnalyticsProvider {
    func logEvent(_ event: NewAnalyticsEvent)
}
