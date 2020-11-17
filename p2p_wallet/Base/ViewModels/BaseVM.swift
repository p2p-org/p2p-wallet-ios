//
//  BaseVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/12/20.
//

import Foundation
import RxSwift
import RxCocoa

class BaseVM<T: Hashable> {
    let disposeBag = DisposeBag()
    var data: T
    let state = BehaviorRelay<FetcherState<T>>(value: .initializing)
    
    init(initialData: T) {
        data = initialData
        bind()
    }
    
    func bind() {}
    
    @discardableResult
    func reload() -> Bool {
        if state.value == .loading {return false}
        return true
    }
    
    var dataDidChange: Observable<Void> {
        state.distinctUntilChanged().map {_ in ()}
    }
}
