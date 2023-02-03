//
//  AnalyticsProvider.swift
//  p2p_wallet
//
//  Created by Ivan on 09.12.2022.
//

import Foundation
import AnalyticsManager

protocol AnalyticsProvider {
    func logEvent(_ event: AnalyticsEvent)
}
