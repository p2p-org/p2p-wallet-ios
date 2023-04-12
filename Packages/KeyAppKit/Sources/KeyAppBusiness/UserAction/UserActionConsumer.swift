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
    associatedtype Event: UserActionEvent

    /// Persistence storage for storage states.
    var persistence: UserActionPersistentStorage { get }

    /// Update stream
    var onUpdate: AnyPublisher<any UserAction, Never> { get }

    /// Fire action.
    func start()

    /// Handle new action, that was initialised by user.
    func process(action: any UserAction)

    /// Handle event.
    func handleEvent(event: Event)
}
