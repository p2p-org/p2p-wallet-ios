//
//  CreateWalletViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import UIKit
import RxSwift
import RxCocoa

enum CreateWalletNavigatableScene {
//    case detail
}

struct CreateWalletViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let bag = DisposeBag()
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<CreateWalletNavigatableScene>()
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Initializer
    init() {
        bind()
    }
    
    // MARK: - Binding
    func bind() {
        
    }
    
    // MARK: - Actions
//    @objc func showDetail() {
//        
//    }
}
