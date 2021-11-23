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
    var currencyModeDriver: Driver<SendTokenChooseTokenAndAmount.CurrencyMode> {get}
    var amountDriver: Driver<Double?> {get}
    
    func navigate(to scene: SendTokenChooseTokenAndAmount.NavigatableScene)
    func back()
    func toggleCurrencyMode()
    func enterAmount(_ amount: Double?)
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
        private let currencyModeSubject = BehaviorRelay<CurrencyMode>(value: .token)
        private let amountSubject = BehaviorRelay<Double?>(value: nil)
        
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
    
    var currencyModeDriver: Driver<SendTokenChooseTokenAndAmount.CurrencyMode> {
        currencyModeSubject.asDriver()
    }
    
    var amountDriver: Driver<Double?> {
        amountSubject.asDriver()
    }
    
    // MARK: - Actions
    func navigate(to scene: SendTokenChooseTokenAndAmount.NavigatableScene) {
        navigationSubject.accept(scene)
    }
    
    func back() {
        onGoBack?()
    }
    
    func toggleCurrencyMode() {
        if currencyModeSubject.value == .token {
            currencyModeSubject.accept(.fiat)
        } else {
            currencyModeSubject.accept(.token)
        }
    }
    
    func enterAmount(_ amount: Double?) {
        amountSubject.accept(amount)
    }
}
