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
    let data: BehaviorRelay<T>
    let state = BehaviorRelay<FetcherState>(value: .initializing)
    
    init(initialData: T) {
        data = BehaviorRelay<T>(value: initialData)
    }
    
    @discardableResult
    func reload() -> Bool {
        if state.value == .loading {return false}
        return true
    }
}
