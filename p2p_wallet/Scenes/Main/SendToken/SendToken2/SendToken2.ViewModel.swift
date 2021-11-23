//
//  SendToken2.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol SendToken2ViewModelType {
    var navigationDriver: Driver<SendToken2.NavigatableScene?> {get}
    func navigate(to scene: SendToken2.NavigatableScene)
}

extension SendToken2 {
    class ViewModel {
        // MARK: - Dependencies
        
        // MARK: - Properties
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
    }
}

extension SendToken2.ViewModel: SendToken2ViewModelType {
    var navigationDriver: Driver<SendToken2.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    // MARK: - Actions
    func navigate(to scene: SendToken2.NavigatableScene) {
        navigationSubject.accept(scene)
    }
}
