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
    
    var state: AsyncValueState<[Account]> { get }

    /// Accounts state
    var statePublisher: AnyPublisher<AsyncValueState<[Account]>, Never> { get }

    /// Update accounts state
    func fetch() async throws
}
