//
//  AuthenticationPresentationStyle.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/01/2022.
//

import Foundation

struct AuthenticationPresentationStyle {
    var title: String = L10n.enterPINCode
    let isRequired: Bool
    let isFullScreen: Bool
    var useBiometry: Bool = true
    var completion: ((_ resetPassword: Bool) -> Void)?

    static func login() -> Self {
        .init(
            isRequired: true,
            isFullScreen: true,
            completion: nil
        )
    }
}
