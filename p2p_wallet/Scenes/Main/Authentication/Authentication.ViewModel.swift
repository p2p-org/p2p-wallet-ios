//
//  Authentication.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/11/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol AuthenticationViewModelType {
    var navigationDriver: Driver<Authentication.NavigatableScene?> {get}
    func showResetPincodeWithASeedPhrase()
    func getCurrentPincode() -> String?
}

extension Authentication {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var accountStorage: KeychainAccountStorage
        
        // MARK: - Properties
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
    }
}

extension Authentication.ViewModel: AuthenticationViewModelType {
    var navigationDriver: Driver<Authentication.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    // MARK: - Actions
    func showResetPincodeWithASeedPhrase() {
        navigationSubject.accept(.resetPincodeWithASeedPhrase)
    }
    
    func getCurrentPincode() -> String? {
        accountStorage.pinCode
    }
}
