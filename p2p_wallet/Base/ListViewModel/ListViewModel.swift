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
    let state = BehaviorRelay<ListFetcherState>(value: .loading(false))
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    var limit = 10
    var offset = 0
    var isPaginationEnabled: Bool {true}
    
    var request: Single<[T]> { fatalError("Must override") }
    
    func reload() {
        items.accept([])
        offset = 0
        fetchNext()
    }
    
    func fetchNext() {
        // prevent dupplicate
        switch state.value {
        case .loading(let isLoading):
            if isLoading {return}
        case .listEnded, .listEmpty:
            return
        case .error:
            break
        }
        
        // assign loading state
        state.accept(.loading(true))
        
        request
            .subscribe { (items) in
                self.handleNewData(items)
            } onError: { (error) in
                self.state.accept(.error(error: error))
            }
            .disposed(by: disposeBag)
    }
    
    func handleNewData(_ newItems: [T]) {
        items.accept(self.join(newItems))
        
        // resign state
        modifyStateAfterRequest(itemsCount: newItems.count)
        
        // get next offset
        offset += limit
    }
    
    func join(_ newItems: [T]) -> [T] {
        items.value + newItems.filter {!items.value.contains($0)}
    }
    
    func modifyStateAfterRequest(itemsCount: Int) {
        if self.isPaginationEnabled {
            if itemsCount == 0 {
                if self.offset == 0 {
                    self.state.accept(.listEmpty)
                } else {
                    if self.items.value.count > 0 {
                        self.state.accept(.listEnded)
                    }
                }
            } else if itemsCount < self.limit {
                self.state.accept(.listEnded)
            } else if itemsCount > self.limit {
                self.state.accept(.listEnded)
            } else {
                self.state.accept(.loading(false))
            }
        } else {
            self.state.accept(itemsCount == 0 ? .listEmpty: .listEnded)
        }
    }
}
