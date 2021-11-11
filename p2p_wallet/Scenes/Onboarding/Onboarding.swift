//
//  Onboarding.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/09/2021.
//

import Foundation

struct Onboarding {
    enum NavigatableScene {
        case createPincode
        case confirmPincode(pincode: UInt)
        case setUpBiometryAuthentication
        case setUpNotifications
        case dismiss
    }
}
