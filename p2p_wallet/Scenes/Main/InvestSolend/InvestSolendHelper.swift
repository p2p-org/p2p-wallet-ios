// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import Solend

enum InvestSolendHelper {
    /// Check current user's action
    ///
    /// - Parameters:
    ///   - notificationService:
    ///   - currentAction:
    /// - Returns: True if there is no action, otherwise false
    static func readyToStartAction(_ notificationService: NotificationService, _ currentAction: SolendAction?) -> Bool {
        if let currentAction = currentAction {
            // There is already running action
            switch currentAction.type {
            case .deposit:
                notificationService
                    .showInAppNotification(
                        .init(
                            emoji: "🕙",
                            message: L10n.SendingYourDepositToSolend.justWaitUntilItSDone.replacingOccurrences(
                                of: "\n",
                                with: " "
                            )
                        )
                    )
                return false
            case .withdraw:
                notificationService
                    .showInAppNotification(
                        .init(
                            emoji: "🕙",
                            message: L10n.WithdrawingYourFundsFromSolend.justWaitUntilItSDone.replacingOccurrences(
                                of: "\n",
                                with: " "
                            )
                        )
                    )
                return false
            }
        }

        return true
    }
}
