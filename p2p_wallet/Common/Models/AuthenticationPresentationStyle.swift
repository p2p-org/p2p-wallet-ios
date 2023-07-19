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
    case withSignOut
    case withLogo
}

struct AuthenticationPresentationStyle {
    let options: Set<AuthenticationOptions>
    var completion: ((_ resetPassword: Bool) -> Void)?
    let onCancel: (() -> Void)?

    init(
        options: Set<AuthenticationOptions> = [],
        completion: ((Bool) -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
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
