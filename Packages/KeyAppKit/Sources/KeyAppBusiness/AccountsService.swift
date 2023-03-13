//
//  File.swift
//
//
//  Created by Giang Long Tran on 12.03.2023.
//

import Combine
import Foundation
import KeyAppKitCore

/// Accounts service
/// This protocol observes account changing in network.
public protocol AccountsService<Account>: AnyObject {
    associatedtype Account

    /// Accounts state
    var state: AsyncValueState<[Account]> { get }

    /// Update accounts state
    func fetch() async throws 
}
