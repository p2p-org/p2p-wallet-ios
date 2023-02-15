//
//  ListViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 15.02.2023.
//

import Combine
import Foundation

class ListAdapter<Iterator: AsyncIteratorProtocol> where Iterator.Element == Identifiable {
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
        var data: [Iterator.Element] = []
        var fetchable: Bool = true
        var error: Error? = nil
    }
    
    // MARK: - Variables
    
    /// Number of items that will be fetched by call ``fetch()``
    private let limit: Int
    
    /// Adapter current state
    @Published private(set) var state: State
    
    /// Iterator that help build a list
    private var iterator: Iterator
    
    /// Current fetching task
    private var currentTask: Task<Void, Error>?
    
    // MARK: - Initializing
    
    init(iterator: Iterator, limit: Int = 20) {
        self.state = .init()
        self.iterator = iterator
        self.limit = limit
    }
    
    // MARK: - Actions
    
    /// Cancel current task and reset data.
    func reset(newIterator: Iterator) {
        // Cancel current task
        currentTask?.cancel()
        currentTask = nil
        
        // Reset state
        state.data = []
        state.status = .ready
        state.error = nil
        
        // Set new iterator
        iterator = newIterator
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
            var fetchedItems: [Item] = []
            
            // Fetching
            do {
                while let item: Item = try await iterator.next(), n > 0 {
                    fetchedItems.append(item)
                    n -= 1
                }
            } catch {
                if !Task.isCancelled {
                    state.error = error
                }
            }
            
            // Ensure unique id in list
            fetchedItems = fetchedItems.filter { fetchedItem in !state.data.contains { $0.id == fetchedItem.id } }
            
            // Update fetchable
            state.fetchable = n > 0
            
            // Update data
            state.data = state.data + fetchedItems
            
            // Finish task
            currentTask = nil
            state.status = .ready
        }
        
        return currentTask
    }
}
