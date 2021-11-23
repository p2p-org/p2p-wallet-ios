//
//  SendTokenChooseTokenAndAmount.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol SendTokenChooseTokenAndAmountViewModelType {
    var navigationDriver: Driver<SendTokenChooseTokenAndAmount.NavigatableScene?> {get}
    func navigate(to scene: SendTokenChooseTokenAndAmount.NavigatableScene)
    func back()
}

extension SendTokenChooseTokenAndAmount {
    class ViewModel {
        // MARK: - Dependencies
        
        // MARK: - Properties
        
        // MARK: - Callback
        var onGoBack: (() -> Void)?
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
    }
}

extension SendTokenChooseTokenAndAmount.ViewModel: SendTokenChooseTokenAndAmountViewModelType {
    var navigationDriver: Driver<SendTokenChooseTokenAndAmount.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    // MARK: - Actions
    func navigate(to scene: SendTokenChooseTokenAndAmount.NavigatableScene) {
        navigationSubject.accept(scene)
    }
    
    func back() {
        onGoBack?()
    }
}
