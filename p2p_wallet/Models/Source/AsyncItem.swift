//
//  AsyncItem.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 19.02.2023.
//

import Combine
import Foundation

//class AsyncItem<T> {
//    typealias Request = () async throws -> T
//    
//    enum Status {
//        case fetching
//        case ready
//    }
//    
//    struct State {
//        var status: Status
//        var item: T
//        var error: Error?
//    }
//    
//    @Published var state: State
//    
//    init(initialItem: T, request: @escaping Request) {
//        state = .init(status: .ready, item: initialItem)
//        self.request = request
//    }
//    
//    private var request: Request
//    
//    private var currentTask: Task<Void, Error>?
//    
//    @discardableResult func fetch() -> Task<Void, Error>? {
//        // Ensure only one task at current moment
//        if let currentTask {
//            return currentTask
//        }
//        
//        // Create a new task
//        currentTask = Task {
//            // Prepare
//            state.status = .fetching
//            state.error = nil
//            
//            // Fetching
//            do {
//                self.state.item = try await request()
//            } catch {
//                if !Task.isCancelled {
//                    state.error = error
//                }
//            }
//            
//            // Finish task
//            currentTask = nil
//            state.status = .ready
//        }
//        
//        return currentTask
//    }
//    
//    func listen<Target: ObservableObject>(target: Target, in storage: inout [AnyCancellable]) where Target.ObjectWillChangePublisher == ObservableObjectPublisher
//    {
//        $state
//            .receive(on: RunLoop.main)
//            .sink { [weak target] _ in
//                target?.objectWillChange.send()
//            }.store(in: &storage)
//    }
//}
