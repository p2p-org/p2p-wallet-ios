//
//  ErrorHandler.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 04.03.2023.
//

import Foundation
import Sentry

extension Error {
    func capture() {
        SentrySDK.capture(error: self)
    }
}
