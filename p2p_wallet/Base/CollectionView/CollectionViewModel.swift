//
//  CollectionViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import Foundation
import RxCocoa

class CollectionViewModel<T: Hashable> {
    // MARK: - Subject
    let list = BehaviorRelay<[T]>(value: [])
}
