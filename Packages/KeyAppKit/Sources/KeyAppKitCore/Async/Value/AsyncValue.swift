//
//  AsyncItem.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 19.02.2023.
//

import Combine
import Foundation

public enum AsynValueStatus {
    case initializing
    case fetching
    case ready
    
    public static func combine(_ status: [Self]) -> Self {
        if status.contains(.initializing) {
            return .initializing
        } else if status.contains(.fetching) {
            return .fetching
        } else {
            return .ready
        }
    }
    
    public static func combine(lhs: Self, rhs: Self) -> Self {
        if lhs == .initializing || rhs == .initializing {
            return .initializing
        } else if lhs == .fetching || rhs == .fetching {
            return .fetching
        } else {
            return .ready
        }
    }
}

public struct AsyncValueState<T> {
    public var status: AsynValueStatus
    public var value: T
    public var error: Error?
    
    public init(status: AsynValueStatus = .initializing, value: T, error: Error? = nil) {
        self.status = status
        self.value = value
        self.error = error
    }
    
    public func apply<Output>(_ transform: (T) -> Output) -> AsyncValueState<Output> {
        .init(
            status: status,
            value: transform(value),
            error: error
        )
    }
    
    public var isFetching: Bool {
        switch status {
        case .initializing:
            return error == nil ? true : false
        case .fetching:
            return true
        case .ready:
            return false
        }
    }
}

public extension AsyncValueState where T: Sequence {
    func innerApply<Output>(_ transform: (T.Element) -> Output) -> AsyncValueState<[Output]> {
        .init(
            status: status,
            value: value.map { transform($0) },
            error: error
        )
    }
}

public class AsyncValue<T>: ObservableObject {
    public typealias Request = () async -> (T?, Error?)
    public typealias ThrowableRequest = () async throws -> T
    
    @Published public var state: AsyncValueState<T>
    
    public init(initialItem: T, request: @escaping Request) {
        state = .init(status: .initializing, value: initialItem)
        self.request = request
    }
    
    public init(initialItem: T, throwableRequest: @escaping ThrowableRequest) {
        state = .init(status: .initializing, value: initialItem)
        request = {
            do {
                return (try await throwableRequest(), nil)
            } catch {
                return (nil, error)
            }
        }
    }
    
    public init(just item: T) {
        state = .init(status: .ready, value: item)
        request = { (item, nil) }
    }
    
    private var request: Request
    
    private var currentTask: Task<Void, Error>?
    
    @discardableResult
    public func fetch() -> Task<Void, Error>? {
        // Ensure only one task at current moment
        if let currentTask {
            return currentTask
        }
        
        // Create a new task
        currentTask = Task {
            defer {
                // Finish task
                currentTask = nil
            }
            
            // Prepare
            if state.status == .ready {
                self.state.status = .fetching
            }
            state.error = nil
            
            // Fetching
            let (value, error) = await request()
            
            if Task.isCancelled { return }
            
            if let value { self.state.value = value }
            self.state.error = error
            
            // Initialising failure
            if state.status == .initializing, error != nil, value == nil {
                self.state.status = .initializing
            } else {
                self.state.status = .ready
            }
        }
        
        return currentTask
    }
    
    public func listen<Target: ObservableObject>(target: Target, in storage: inout [AnyCancellable]) where Target.ObjectWillChangePublisher == ObservableObjectPublisher
    {
        $state
            .receive(on: RunLoop.main)
            .sink { [weak target] _ in
                target?.objectWillChange.send()
            }.store(in: &storage)
    }
}
