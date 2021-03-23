//
//  ReceiveTokenViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import UIKit
import RxSwift
import RxCocoa

enum ReceiveTokenNavigatableScene {
//    case detail
}

protocol WalletsRepository {
    var stateObservable: Observable<FetcherState<[Wallet]>> {get}
}

class ReceiveTokenViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    let repository: WalletsRepository
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<ReceiveTokenNavigatableScene>()
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Initializers
    init(walletsRepository: WalletsRepository) {
        self.repository = walletsRepository
    }
    
    // MARK: - Actions
    @objc func selectWallet() {
        
    }
    
    @objc func copyToClipboard() {
        
    }
    
    @objc func share() {
        
    }
}
