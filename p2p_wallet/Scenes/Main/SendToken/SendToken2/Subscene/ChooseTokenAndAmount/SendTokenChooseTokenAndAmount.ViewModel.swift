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
    var walletDriver: Driver<Wallet?> {get}
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
        private let walletSubject = BehaviorRelay<Wallet?>(value: nil)
        
        // MARK: - Initializer
        init(wallet: Wallet? = nil) {
            walletSubject.accept(wallet)
        }
    }
}

extension SendTokenChooseTokenAndAmount.ViewModel: SendTokenChooseTokenAndAmountViewModelType {
    var navigationDriver: Driver<SendTokenChooseTokenAndAmount.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var walletDriver: Driver<Wallet?> {
        walletSubject.asDriver()
    }
    
    // MARK: - Actions
    func navigate(to scene: SendTokenChooseTokenAndAmount.NavigatableScene) {
        navigationSubject.accept(scene)
    }
    
    func back() {
        onGoBack?()
    }
}
