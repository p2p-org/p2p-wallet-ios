//
//  File.swift
//
//
//  Created by Giang Long Tran on 11.04.2023.
//

import Foundation
import KeyAppBusiness
import Wormhole

public enum WormholeSendUserActionEvent: UserActionEvent {
    case track(WormholeSendStatus)
    case sendFailure(message: String, error: UserActionError)
}
