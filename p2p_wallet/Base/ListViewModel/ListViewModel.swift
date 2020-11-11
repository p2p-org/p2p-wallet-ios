//
//  ListViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/4/20.
//

import Foundation
import RxSwift
import RxCocoa

class ListViewModel<T: Hashable> {
    // MARK: - Subjects
    let items = BehaviorRelay<[T]>(value: [])
    let state = BehaviorRelay<FetcherState>(value: .loading)
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    var limit = 10
    var offset = 0
    var isPaginationEnabled: Bool {true}
    var isLastPageLoaded = false
    var isListEmpty: Bool {isLastPageLoaded && items.value.count == 0}
    
    var request: Single<[T]> { Single<[T]>.just([]).delay(.seconds(2), scheduler: MainScheduler.instance) // delay for simulating loading
    }
    
    func reload() {
        items.accept([])
        offset = 0
        isLastPageLoaded = false
        fetchNext()
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
        items.accept(self.join(newItems))
        
        // resign state
        if !isPaginationEnabled || newItems.count < limit {
            isLastPageLoaded = true
        }
        
        state.accept(.loaded)
        
        // get next offset
        offset += limit
    }
    
    func join(_ newItems: [T]) -> [T] {
        items.value + newItems.filter {!items.value.contains($0)}
    }
}
