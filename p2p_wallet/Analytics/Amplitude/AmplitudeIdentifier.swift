//
//  AmplitudeIdentifier.swift
//  p2p_wallet
//
//  Created by Ivan on 20.09.2022.
//

import AnalyticsManager

enum AmplitudeIdentifier: MirrorableEnum {
    case userHasPositiveBalance(positive: Bool)
    case userAggregateBalance(balance: Double)

    // Onboarding
    case userRestoreMethod(restoreMethod: String)
    case userDeviceshare(deviceshare: Bool)
    
    var name: String {
        mirror.label.snakeAndFirstUppercased ?? ""
    }

    var value: Any {
        mirror.params.values.first ?? ""
    }
}
