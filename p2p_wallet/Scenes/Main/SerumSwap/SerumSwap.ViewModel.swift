//
//  SerumSwap.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/08/2021.
//

import Foundation
import RxSwift
import RxCocoa

extension SerumSwap {
    struct ViewModel: SerumSwapViewModelType {
        // MARK: - Dependencies
        private let analyticsManager: AnalyticsManager
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        
        // MARK: - Input
        let inputAmountSubject: PublishRelay<String?> = .init()
        let estimatedAmountSubject: PublishRelay<String?> = .init()
        
        // MARK: - Subject
        private let navigationRelay = BehaviorRelay<NavigatableScene?>(value: nil)
        private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
        
        private let useAllBalanceSubject = PublishSubject<Double?>()
        private let sourceWalletRelay = BehaviorRelay<Wallet?>(value: nil)
        private let inputAmountRelay = BehaviorRelay<Double?>(value: nil)
        private let availableAmountRelay = BehaviorRelay<Double?>(value: nil)
        
        private let destinationWalletRelay = BehaviorRelay<Wallet?>(value: nil)
        private let estimatedAmountRelay = BehaviorRelay<Double?>(value: nil)
        
        private let slippageRelay = BehaviorRelay<Double?>(value: Defaults.slippage)
        
        private let errorRelay = BehaviorRelay<String?>(value: nil)
        
        // MARK: - Initializer
        init(analyticsManager: AnalyticsManager) {
            self.analyticsManager = analyticsManager
            bind()
        }
        
        /// Bind subjects
        private func bind() {
            
        }
    }
}

extension SerumSwap.ViewModel {
    // MARK: - Output
    var navigationDriver: Driver<SerumSwap.NavigatableScene?> { navigationRelay.asDriver() }
    var isLoadingDriver: Driver<Bool> { isLoadingRelay.asDriver() }
    var sourceWalletDriver: Driver<Wallet?> { sourceWalletRelay.asDriver() }
    var availableAmountDriver: Driver<Double?> {availableAmountRelay.asDriver()}
    var inputAmountDriver: Driver<Double?> {inputAmountRelay.asDriver()}
    var destinationWalletDriver: Driver<Wallet?> {destinationWalletRelay.asDriver()}
    var estimatedAmountDriver: Driver<Double?> {estimatedAmountRelay.asDriver()}
    var errorDriver: Driver<String?> {errorRelay.asDriver()}
    var exchangeRateDriver: Driver<SerumSwap.ExchangeRate?>
    var slippageDriver: Driver<Double?>
    var isSwappableDriver: Driver<Bool>
    
    var useAllBalanceDidTapSignal: Signal<Double?> {useAllBalanceSubject.asSignal(onErrorJustReturn: nil)}
}

extension SerumSwap.ViewModel {
    // MARK: - Actions
    func navigate(to scene: NavigatableScene) {
        switch scene {
        case .chooseSourceWallet:
            <#code#>
        case .chooseDestinationWallet:
            <#code#>
        case .settings:
            <#code#>
        case .chooseSlippage:
            <#code#>
        case .swapFees:
            <#code#>
        case .processTransaction(request: let request, transactionType: let transactionType):
            <#code#>
        }
        navigationRelay.accept(scene)
    }
    
    func useAllBalance() {
        <#code#>
    }
    
    func log(_ event: AnalyticsEvent) {
        analyticsManager.log(event: event)
    }
    
    func swapSourceAndDestination() {
        <#code#>
    }
    
    func reverseExchangeRate() {
        <#code#>
    }
    
    func authenticateAndSwap() {
        <#code#>
    }
    
    func changeSlippage(to slippage: Double) {
        <#code#>
    }
}
