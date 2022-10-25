//
//  AmplitudeIdentifier.swift
//  p2p_wallet
//
//  Created by Ivan on 20.09.2022.
//

import AnalyticsManager

enum AmplitudeIdentifier: AnalyticsIdentifier {
    case userHasPositiveBalance(positive: Bool)
    case userAggregateBalance(balance: Double)

    // Onboarding
    case userRestoreMethod(restoreMethod: String)
    case userDeviceshare(deviceshare: Bool)
}
