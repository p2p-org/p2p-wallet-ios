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
}

struct AuthenticationPresentationStyle {
    var title: String
    let options: Set<AuthenticationOptions>
    var completion: ((_ resetPassword: Bool) -> Void)?

    init(
        title: String = L10n.enterPINCode,
        options: Set<AuthenticationOptions> = [],
        completion: ((Bool) -> Void)? = nil
    ) {
        self.title = title
        self.options = options
        self.completion = completion
    }

    /**
     Default authentication style when user first login to the app.
     - Returns: style
     */
    static func login() -> Self {
        .init(
            options: [.required, .fullscreen, .withSignOut],
            completion: nil
        )
    }
}
