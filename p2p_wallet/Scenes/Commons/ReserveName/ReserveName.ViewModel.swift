//
//  ReserveName.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/10/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol ReserveNameViewModelType {
    var navigationDriver: Driver<ReserveName.NavigatableScene?> {get}
    func showCaptcha()
}

extension ReserveName {
    class ViewModel {
        // MARK: - Dependencies
        
        // MARK: - Properties
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
    }
}

extension ReserveName.ViewModel: ReserveNameViewModelType {
    var navigationDriver: Driver<ReserveName.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    // MARK: - Actions
    func showCaptcha() {
        navigationSubject.accept(.showCaptcha)
    }
}
