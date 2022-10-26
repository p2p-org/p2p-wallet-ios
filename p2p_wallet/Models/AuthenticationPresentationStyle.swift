//
//  AuthenticationPresentationStyle.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/01/2022.
//

import Foundation

enum AuthenticationOptions {
    case required
    case fullscreen
    case disableBiometric
    case withResetPassword
    case withSignOut
    case withLogo
}

struct AuthenticationPresentationStyle {
    var title: String
    let options: Set<AuthenticationOptions>
    var completion: ((_ resetPassword: Bool) -> Void)?
    let onCancel: (() -> Void)?

    init(
        title: String = L10n.enterPINCode,
        options: Set<AuthenticationOptions> = [],
        completion: ((Bool) -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.title = title
        self.options = options
        self.completion = completion
        self.onCancel = onCancel
    }

    /**
     Default authentication style when user first login to the app.
     - Returns: style
     */
    static func login() -> Self {
        .init(
            options: [.required, .fullscreen, .withSignOut, .withLogo],
            completion: nil
        )
    }
}
