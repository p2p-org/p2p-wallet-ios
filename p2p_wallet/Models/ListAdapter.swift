//
//  ListViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 15.02.2023.
//

import Combine
import Foundation

struct AnyAsyncSequence<Element>: AsyncSequence {
    typealias AsyncIterator = AnyAsyncIterator<Element>
    typealias Element = Element

    let _makeAsyncIterator: () -> AnyAsyncIterator<Element>

    struct AnyAsyncIterator<Element>: AsyncIteratorProtocol {
        typealias Element = Element

        private let _next: () async throws -> Element?

        init<I: AsyncIteratorProtocol>(itr: I) where I.Element == Element {
            var itr = itr
            self._next = {
                try await itr.next()
            }
        }

        mutating func next() async throws -> Element? {
            return try await _next()
        }
    }

    init<S: AsyncSequence>(seq: S) where S.Element == Element {
        self._makeAsyncIterator = {
            AnyAsyncIterator(itr: seq.makeAsyncIterator())
        }
    }

    func makeAsyncIterator() -> AnyAsyncIterator<Element> {
        return _makeAsyncIterator()
    }
}

extension AsyncSequence {
    func eraseToAnyAsyncSequence() -> AnyAsyncSequence<Element> {
        AnyAsyncSequence(seq: self)
    }
}

class ListAdapter<Sequence: AsyncSequence> where Sequence.Element: Identifiable {
    // MARK: - Nested types
    
    /// List adapter status
    enum Status {
        /// Adapter is fetching new data
        case fetching
        
        /// Adapter is ready to fetch new data
        case ready
    }
    
    /// List adapter state
    struct State {
        var status: Status = .ready
        var data: [Sequence.Element] = []
        var fetchable: Bool = true
        var error: Error? = nil
    }
    
    // MARK: - Variables
    
    /// Number of items that will be fetched by call ``fetch()``
    private let limit: Int
    
    /// Adapter current state
    @Published private(set) var state: State
    
    /// Iterator that help build a list
    private var sequence: Sequence
    
    private var iterator: Sequence.AsyncIterator
    
    /// Current fetching task
    private var currentTask: Task<Void, Error>?
    
    // MARK: - Initializing
    
    init(sequence: Sequence, limit: Int = 20) {
        self.state = .init()
        self.sequence = sequence
        self.iterator = sequence.makeAsyncIterator()
        self.limit = limit
    }
    
    // MARK: - Actions
    
    /// Cancel current task and reset data.
    func reset() {
        // Cancel current task
        currentTask?.cancel()
        currentTask = nil
        
        // Reset state
        state.data = []
        state.status = .ready
        state.error = nil
        
        // Set new iterator
        iterator = sequence.makeAsyncIterator()
    }
 
    /// Fetch new data
    @discardableResult func fetch() -> Task<Void, Error>? {
        // Ensure only one task at current moment
        if let currentTask {
            return currentTask
        }
        
        // Ensure is fetchable
        guard state.fetchable else {
            return nil
        }
        
        // Create a new task
        currentTask = Task {
            state.status = .fetching
            
            // Preparing
            var n = limit
            var fetchedItems: [Sequence.Element] = []
            
            // Fetching
            do {
                while let item: Sequence.Element = try await iterator.next(), n > 0 {
                    fetchedItems.append(item)
                    n -= 1
                }
            } catch {
                if !Task.isCancelled {
                    print(error)
                    state.error = error
                }
            }
            
            // Ensure unique id in list
            fetchedItems = fetchedItems.filter { fetchedItem in !state.data.contains { $0.id == fetchedItem.id } }
            
            // Update fetchable
            state.fetchable = n == 0
            
            // Update data
            state.data = state.data + fetchedItems
            
            // Finish task
            currentTask = nil
            state.status = .ready
        }
        
        return currentTask
    }
    
    func listen<Target: ObservableObject>(target: Target, in storage: inout [AnyCancellable]) where Target.ObjectWillChangePublisher == ObservableObjectPublisher
    {
        $state
            .receive(on: RunLoop.main)
            .sink { [weak target] _ in
                target?.objectWillChange.send()
            }.store(in: &storage)
    }
}
