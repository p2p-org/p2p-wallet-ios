//
//  File.swift
//
//
//  Created by Giang Long Tran on 30.03.2023.
//

import Foundation
import KeyAppKitCore

public enum WormholeSendInputAction {
    /// User enter new amount. Expected value in token. Example: 12.4567.
    case updateInput(amount: String)

    /// Update selected account.
    case updateSolanaAccount(account: SolanaAccount)

    /// Derivate output from input.
    case calculate
}
