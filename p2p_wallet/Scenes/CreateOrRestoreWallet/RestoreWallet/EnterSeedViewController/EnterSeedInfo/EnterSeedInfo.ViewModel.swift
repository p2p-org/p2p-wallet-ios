//
//  EnterSeedInfo.ViewModel.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 18.11.2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol EnterSeedInfoViewModelType {
    var navigationDriver: Driver<EnterSeedInfo.NavigatableScene?> { get }
    func done()
}

extension EnterSeedInfo {
    class ViewModel {
        // MARK: - Dependencies
        
        // MARK: - Properties
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        
        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
    }
}

extension EnterSeedInfo.ViewModel: EnterSeedInfoViewModelType {
    var navigationDriver: Driver<EnterSeedInfo.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    // MARK: - Actions
    func done() {
        navigationSubject.accept(.done)
    }
}
