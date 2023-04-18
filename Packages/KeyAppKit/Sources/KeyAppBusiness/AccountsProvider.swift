//
//  File.swift
//
//
//  Created by Giang Long Tran on 12.03.2023.
//

import Combine
import Foundation
import KeyAppKitCore

/// Protocol for provider that provides some kind of accounts.
public protocol AccountsProvider: AnyObject {
    associatedtype Account

    /// Accounts state
    var state: AsyncValueState<[Account]> { get }

    /// Update accounts state
    func fetch() async throws 
}
