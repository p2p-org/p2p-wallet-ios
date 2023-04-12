//
//  File.swift
//
//
//  Created by Giang Long Tran on 11.04.2023.
//

import Foundation
import KeyAppBusiness

public enum WormholeSendUserActionError {
    public static let domain = "WormholeSendUserActionConsumer"

    public static let topUpFailure = UserActionError(
        domain: domain,
        code: 1,
        reason: "Top up relay account failure"
    )
    
    
    public static let preparingTransactionFailure = UserActionError(
        domain: domain,
        code: 2,
        reason: "Failed preparing transaction for send"
    )
    
    public static let feeRelaySignFailure = UserActionError(
        domain: domain,
        code: 3,
        reason: "Feerelay signs with failure"
    )
    
    public static let submittingToBlockchainFailure = UserActionError(
        domain: domain,
        code: 4,
        reason: "Sunmitting to blockchain occurs an error."
    )
    
    public static let sendingFailure = UserActionError(
        domain: domain,
        code: 4,
        reason: "Crosschain sending failure"
    )
}
