//
//  File.swift
//
//
//  Created by Giang Long Tran on 30.03.2023.
//

import Combine
import Foundation

public protocol UserActionConsumer {
    associatedtype Action: UserAction

    /// Persistence storage for storage states.
    var persistence: UserActionPersistentStorage { get }

    /// Update stream
    var onUpdate: PassthroughSubject<UserAction, Never> { get }

    /// Fire action.
    func start()

    /// Handle new action.
    func process(action: UserAction)
}
