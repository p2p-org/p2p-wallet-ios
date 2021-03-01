//
//  ListViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/4/20.
//

import Foundation
import RxSwift
import RxCocoa

class ListViewModel<T: Hashable>: BaseVM<[T]> {
    // MARK: - Subjects
    var items: [T] {
        get {data}
        set {data = newValue}
    }
    var isSearchingOffline: Bool {searchResult != nil}
    
    // MARK: - Properties
    var limit = 10
    var offset = 0
    var isPaginationEnabled: Bool {true}
    var isLastPageLoaded = false
    var isListEmpty: Bool {isLastPageLoaded && items.count == 0}
    var searchResult: [T]?
    
    // MARK: - Initializer
    init(prefetch: Bool = true) {
        super.init(initialData: [])
        if prefetch {
            reload()
        }
    }
    
    // MARK: - Methods
    override func reload() {
        data = []
        offset = 0
        isLastPageLoaded = false
        super.reload()
    }
    
    func fetchNext() {
        super.reload()
    }
    
    func refresh() {
        reload()
    }
    
    override func shouldReload() -> Bool {
        super.shouldReload() && !isLastPageLoaded
    }
    
    override func handleNewData(_ newItems: [T]) {
        data = self.join(newItems)
        
        // resign state
        if !isPaginationEnabled || newItems.count < limit {
            isLastPageLoaded = true
        }
        
        state.accept(.loaded(items))
        
        // get next offset
        offset += limit
    }
    
    func join(_ newItems: [T]) -> [T] {
        if !isPaginationEnabled {
            return newItems
        }
        return items + newItems.filter {!items.contains($0)}
    }
    
    // MARK: - Helper
    @discardableResult
    func updateItem(where predicate: (T) -> Bool, transform: (T) -> T?) -> Bool {
        switch state.value {
        case .loaded :
            // modify search result
            var searchResultChanged = false
            if let index = searchResult?.firstIndex(where: predicate),
               let item = transform(searchResult![index]),
               item != searchResult![index]
            {
                searchResultChanged = true
                searchResult![index] = item
            }
            
            // modify items
            var itemsChanged = false
            if let index = items.firstIndex(where: predicate),
               let item = transform(items[index]),
               item != items[index]
            {
                itemsChanged = true
                items[index] = item
            }
            
            // update state
            if isSearchingOffline {
                if searchResultChanged {
                    state.accept(.loaded(searchResult!))
                }
                return searchResultChanged
            } else {
                if itemsChanged {
                    state.accept(.loaded(items))
                }
                return itemsChanged
            }
        default:
            return false
        }
    }
    
    func insert(_ item: T, where predicate: (T) -> Bool, shouldUpdate: Bool = false)
    {
        guard let index = items.firstIndex(where: predicate) else {
            items.append(item)
            state.accept(.loaded(items))
            return
        }
        if shouldUpdate && items[index] != item {
            items[index] = item
            state.accept(.loaded(items))
        }
    }
    
    @discardableResult
    func removeItem(where predicate: (T) -> Bool) -> T? {
        var result: T?
        if let index = searchResult?.firstIndex(where: predicate) {
            result = searchResult?.remove(at: index)
        }
        
        if let index = items.firstIndex(where: predicate) {
            result = items.remove(at: index)
        }
        
        if isSearchingOffline {
            state.accept(.loaded(searchResult!))
        } else {
            state.accept(.loaded(items))
        }
        
        return result
    }
    
    func offlineSearch(query: String) {
        let query = query.lowercased()
        if query.isEmpty {
            searchResult = nil
            state.accept(.loaded(items))
            return
        }
        searchResult = items
            .filter {self.offlineSearchPredicate(item: $0, lowercasedQuery: query)}
        state.accept(.loaded(searchResult!))
    }
    
    func offlineSearchPredicate(item: T, lowercasedQuery query: String) -> Bool
    {
        fatalError("Must implement")
    }
    
    func itemAtIndex(_ index: Int) -> T? {
        if isSearchingOffline {
            if index < searchResult!.count {
                return searchResult![index]
            }
            return nil
        } else {
            if index < data.count {
                return data[index]
            }
            return nil
        }
    }
}
