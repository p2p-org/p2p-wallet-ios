// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation

public protocol State: Equatable {
    associatedtype Event
    associatedtype Provider

    static var initialState: Self { get }

    func accept(currentState: Self, event: Event, provider: Provider) async throws -> Self
}

public actor StateMachine<S: State> {
    private nonisolated let stateSubject: CurrentValueSubject<S, Never>
    
    public nonisolated var currentState: S { stateSubject.value }
    public nonisolated var stateStream: AnyPublisher<S, Never> { stateSubject.eraseToAnyPublisher() }
    
    private let provider: S.Provider
    
    public init(initialState: S? = nil, provider: S.Provider) {
        self.provider = provider
        stateSubject = .init(initialState ?? S.initialState)
    }
    
    @discardableResult
    public func accept(event: S.Event) async throws -> S {
        do {
            let state = try await currentState.accept(currentState: stateSubject.value, event: event, provider: provider)
            stateSubject.send(state)
            return state
        } catch {
            throw error
        }
    }
}

public struct HierarchyStateMachine<S: State> {
    private let callback: (S.Event) async throws -> Void
    
    public init(callback: @escaping (S.Event) async throws -> Void) {
        self.callback = callback
    }
    
    func accept(event: S.Event) async throws {
        try await callback(event)
    }
}

public enum StateMachineError: Error {
    case invalidEvent
}

// Fancy custom operator 😇
infix operator <-

public extension StateMachine {
    static func <-(lhs: inout StateMachine, rhs: S.Event) async throws -> S {
        try await lhs.accept(event: rhs)
    }
}

extension HierarchyStateMachine {
    public static func <-(lhs: HierarchyStateMachine, rhs: S.Event) async throws {
        try await lhs.accept(event: rhs)
    }
}

public extension State {
    static func <-(lhs: Self, rhs: (event: Event, provider: Provider)) async throws -> Self {
        try await lhs.accept(currentState: lhs, event: rhs.event, provider: rhs.provider)
    }
}
