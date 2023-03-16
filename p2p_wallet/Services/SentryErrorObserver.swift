//
//  SentryErrorObserver.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 10.03.2023.
//

import Foundation
import KeyAppKitCore
import Sentry

class SentryErrorObserver: ErrorObserver {
    func handleError(_ error: Error) {
        // Debug print
        #if DEBUG
        debugPrint(error)
        #endif
        
        // Forward to sentry
        SentrySDK.capture(error: error)
    }
}
