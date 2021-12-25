//
//  AuthenticationHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 21/05/2021.
//

import Foundation

struct AuthenticationPresentationStyle {
    var title: String = L10n.enterPINCode
    let isRequired: Bool
    let isFullScreen: Bool
    var useBiometry: Bool = true
    var completion: (() -> Void)?
    
    static func login() -> Self {
        .init(
            isRequired: true,
            isFullScreen: true,
            completion: nil
        )
    }
}

protocol AuthenticationHandler {
    func authenticate(presentationStyle: AuthenticationPresentationStyle?)
    func pauseAuthentication(_ isPaused: Bool)
}

// IMPORTANT: DeviceOwnerAuthenticationHandler must be separated from AuthenticationHandler and has to be perform on Root, because at RestoreWallet, there is no passcode.
protocol DeviceOwnerAuthenticationHandler {
    func requiredOwner(onSuccess: (() -> Void)?, onFailure: ((String?) -> Void)?)
}
