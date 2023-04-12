//
//  File.swift
//
//
//  Created by Giang Long Tran on 11.04.2023.
//

import Foundation
import KeyAppBusiness

public enum WormholeClaimUserActionError {
    public static let domain = "WormholeClaimUserActionConsumer"

    public static let invalidToken = UserActionError(
        domain: domain,
        code: 1,
        reason: "Can not resolve token for new bundle"
    )

    public static let submitError = UserActionError(
        domain: "WormholeClaimUserActionConsumer",
        code: 2,
        reason: "Sending Ethereum bundle returns with error"
    )
    
    public static let claimFailure = UserActionError(
        domain: "WormholeClaimUserActionConsumer",
        code: 3,
        reason: "Claiming is failed"
    )
}
