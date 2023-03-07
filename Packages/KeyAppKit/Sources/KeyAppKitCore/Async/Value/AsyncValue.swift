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
}

extension AsyncValueState where T: Sequence {
    public func innerApply<Output>(_ transform: (T.Element) -> Output) -> AsyncValueState<[Output]> {
        .init(
            status: status,
            value: value.map { transform($0) },
            error: error
        )
    }
}

public class AsyncValue<T> {
    public typealias Request = () async throws -> T
    
    @Published public var state: AsyncValueState<T>
    
    public init(initialItem: T, request: @escaping Request) {
        state = .init(status: .initializing, value: initialItem)
        self.request = request
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
            // Prepare
            if state.status == .ready {
                state.status = .fetching
            }
            state.error = nil
            
            // Fetching
            do {
                self.state.value = try await request()
            } catch {
                if !Task.isCancelled {
                    state.error = error
                }
            }
            
            // Finish task
            currentTask = nil
            state.status = .ready
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
