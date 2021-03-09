//
//  ProcessTransactionViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/03/2021.
//

import UIKit
import RxSwift
import RxCocoa

enum ProcessTransactionNavigatableScene {
//    case detail
}

class ProcessTransactionViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<ProcessTransactionNavigatableScene>()
    
    let transaction = BehaviorRelay<Transaction?>(value: nil)
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    
    // MARK: - Actions
//    @objc func showDetail() {
//        
//    }
}
