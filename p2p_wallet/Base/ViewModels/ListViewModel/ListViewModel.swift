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
    
    // MARK: - Properties
    var limit = 10
    var offset = 0
    var isPaginationEnabled: Bool {true}
    var isLastPageLoaded = false
    var isListEmpty: Bool {isLastPageLoaded && items.count == 0}
    
    var request: Single<[T]> { Single<[T]>.just([]).delay(.seconds(2), scheduler: MainScheduler.instance) // delay for simulating loading
    }
    
    init() {
        super.init(initialData: [])
        reload()
    }
    
    func reload() {
        data = []
        offset = 0
        isLastPageLoaded = false
        fetchNext()
    }
    
    func refresh() {
        reload()
    }
    
    func fetchNext() {
        // prevent dupplicate
        if state.value == .loading || isLastPageLoaded {return}
        
        // assign loading state
        
        state.accept(.loading)
        
        request
            .subscribe { (items) in
                self.handleNewData(items)
            } onError: { (error) in
                self.state.accept(.error(error))
            }
            .disposed(by: disposeBag)
    }
    
    func handleNewData(_ newItems: [T]) {
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
    func updateItem(where predicate: (T) -> Bool, transform: (T) -> T) -> Bool {
        guard let index = items.firstIndex(where: predicate) else {
            return false
        }
        items[index] = transform(items[index])
        state.accept(.loaded(items))
        return true
    }
}
