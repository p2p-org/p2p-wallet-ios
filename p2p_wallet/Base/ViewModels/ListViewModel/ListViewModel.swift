//
//  ListViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/4/20.
//

import Foundation
import RxSwift
import RxCocoa

class ListViewModel<T: ListItemType>: BaseVM<[T]> {
    // MARK: - Subjects
    var items: [T] {
        get {data}
        set {data = newValue}
    }
    
    // MARK: - Properties
    var limit = 10
    var offset = 0
    var isPaginationEnabled: Bool {true}
    var isLastPageLoaded = false
    var isListEmpty: Bool {isLastPageLoaded && items.count == 0}
    
    // MARK: - Initializer
    init() {
        super.init(initialData: [])
        reload()
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
        return items + newItems.filter {!items.map{$0.id}.contains($0.id)}
    }
    
    // MARK: - Helper
    @discardableResult
    func updateItem(where predicate: (T) -> Bool, transform: (T) -> T?) -> Bool {
        guard let index = items.firstIndex(where: predicate),
              let item = transform(items[index])
        else {
            return false
        }
        if items[index] != item {
            items[index] = item
            state.accept(.loaded(items))
            return true
        }
        return false
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
        guard let index = items.firstIndex(where: predicate) else {
            return nil
        }
        let result = items.remove(at: index)
        state.accept(.loaded(items))
        return result
    }
}
