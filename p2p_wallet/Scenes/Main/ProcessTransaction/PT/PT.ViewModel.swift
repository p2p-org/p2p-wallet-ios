//
//  PT.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/12/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol PTViewModelType {
    var navigationDriver: Driver<PT.NavigatableScene?> {get}
    func navigate(to scene: PT.NavigatableScene)
}

extension PT {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var authenticationHandler: AuthenticationHandler
        @Injected private var renVMBurnAndReleaseService: RenVMBurnAndReleaseServiceType
        
        // MARK: - Properties
        private let transaction: ProcessTransactionTransactionType
        
        // MARK: - Properties
        init(transaction: ProcessTransactionTransactionType) {
            self.transaction = transaction
        }
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
    }
}

extension PT.ViewModel: PTViewModelType {
    var navigationDriver: Driver<PT.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    // MARK: - Actions
    func navigate(to scene: PT.NavigatableScene) {
        navigationSubject.accept(scene)
    }
}
