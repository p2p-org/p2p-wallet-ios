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
    var useBiometry: Bool
    var completion: (() -> Void)?
    
    static func login() -> Self {
        .init(
            isRequired: true,
            isFullScreen: true,
            useBiometry: true,
            completion: nil
        )
    }
}

protocol AuthenticationHandler {
    func authenticate(presentationStyle: AuthenticationPresentationStyle)
    func pauseAuthentication(_ isPaused: Bool)
}
