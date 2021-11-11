//
//  VerifySecurityKeys.ViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 11.11.21.
//

import Foundation
import RxSwift
import RxCocoa

protocol VerifySecurityKeysViewModelType {
    var navigationDriver: Driver<VerifySecurityKeys.NavigatableScene?> { get }
    func showDetail()
}

extension VerifySecurityKeys {
    class ViewModel {
        // MARK: - Dependencies
        
        // MARK: - Properties
        let keyPhrase: [String]
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        
        init(keyPhrase: [String]) {
            self.keyPhrase = keyPhrase
        }
    }
}

extension VerifySecurityKeys.ViewModel: VerifySecurityKeysViewModelType {
    var navigationDriver: Driver<VerifySecurityKeys.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    // MARK: - Actions
    func showDetail() {
        navigationSubject.accept(.detail)
    }
}
