//
//  File.swift
//
//
//  Created by Giang Long Tran on 11.04.2023.
//

import Foundation
import KeyAppBusiness

public enum WormholeClaimUserActionEvent: UserActionEvent {
    case track(WormholeBundleStatus)

    case claimFailure(bundleID: String, reason: UserActionError)
    case claimInProgress(bundleID: String)
}
