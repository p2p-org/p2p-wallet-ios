//
//  SendToken.ChooseTokenAndAmount.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation
import RxSwift
import RxCocoa
import SolanaSwift

protocol SendTokenChooseTokenAndAmountViewModelType: WalletDidSelectHandler {
    var navigationDriver: Driver<SendToken.ChooseTokenAndAmount.NavigatableScene?> {get}
    var walletDriver: Driver<Wallet?> {get}
    var currencyModeDriver: Driver<SendToken.ChooseTokenAndAmount.CurrencyMode> {get}
    var amountDriver: Driver<Double?> {get}
    var errorDriver: Driver<SendToken.ChooseTokenAndAmount.Error?> {get}
    
    func navigate(to scene: SendToken.ChooseTokenAndAmount.NavigatableScene)
    func back()
    func toggleCurrencyMode()
    func enterAmount(_ amount: Double?)
    func chooseWallet(_ wallet: Wallet)
    
    func calculateAvailableAmount() -> Double?
    
    func next()
}

extension SendTokenChooseTokenAndAmountViewModelType {
    func walletDidSelect(_ wallet: Wallet) {
        chooseWallet(wallet)
    }
}

extension SendToken.ChooseTokenAndAmount {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        
        // MARK: - Callback
        var onGoBack: (() -> Void)?
        
        // MARK: - Subject
        // Subjects from parent
        private let walletSubject: BehaviorRelay<Wallet?>
        private let amountInLamportsSubject: BehaviorRelay<SolanaSDK.Lamports?>
        
        // Own subjects
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let currencyModeSubject = BehaviorRelay<CurrencyMode>(value: .token)
        private let amountSubject = BehaviorRelay<Double?>(value: nil)
        
        // MARK: - Initializer
        init(walletSubject: BehaviorRelay<Wallet?>, amountInLamportsSubject: BehaviorRelay<SolanaSDK.Lamports?>) {
            self.walletSubject = walletSubject
            self.amountInLamportsSubject = amountInLamportsSubject
            bind()
        }
        
        private func bind() {
            #if DEBUG
            amountSubject.subscribe(onNext: {print($0 ?? 0)}).disposed(by: disposeBag)
            #endif
        }
    }
}

extension SendToken.ChooseTokenAndAmount.ViewModel: SendTokenChooseTokenAndAmountViewModelType {
    var navigationDriver: Driver<SendToken.ChooseTokenAndAmount.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var walletDriver: Driver<Wallet?> {
        walletSubject.asDriver()
    }
    
    var currencyModeDriver: Driver<SendToken.ChooseTokenAndAmount.CurrencyMode> {
        currencyModeSubject.asDriver()
    }
    
    var amountDriver: Driver<Double?> {
        amountSubject.asDriver()
    }
    
    var errorDriver: Driver<SendToken.ChooseTokenAndAmount.Error?> {
        Driver.combineLatest(
            walletDriver,
            amountDriver,
            currencyModeDriver
        )
            .map {[weak self] wallet, amount, _ in
                if wallet == nil {return .destinationWalletIsMissing}
                if amount == nil || (amount ?? 0) <= 0 {return .invalidAmount}
                if (amount ?? 0) > (self?.calculateAvailableAmount() ?? 0) {return .insufficientFunds}
                return nil
            }
    }
    
    // MARK: - Actions
    func navigate(to scene: SendToken.ChooseTokenAndAmount.NavigatableScene) {
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
    
    func chooseWallet(_ wallet: Wallet) {
        analyticsManager.log(
            event: .sendSelectTokenClick(tokenTicker: wallet.token.symbol)
        )
        walletSubject.accept(wallet)
    }
    
    func calculateAvailableAmount() -> Double? {
        guard let wallet = walletSubject.value else {return nil}
        // all amount
        var availableAmount = wallet.amount ?? 0
        
        // convert to fiat in fiat mode
        if currencyModeSubject.value == .fiat {
            availableAmount = (availableAmount * wallet.priceInCurrentFiat).rounded(decimals: wallet.token.decimals)
        }
        
        #if DEBUG
        print("availableAmount \(availableAmount)")
        #endif
        
        // return
        return availableAmount > 0 ? availableAmount: 0
    }
    
    func next() {
        guard let wallet = walletSubject.value,
              let totalLamports = wallet.lamports,
              var amount = amountSubject.value
        else {return}
        
        // convert value
        if currencyModeSubject.value == .fiat, (wallet.priceInCurrentFiat ?? 0) > 0 {
            amount /= wallet.priceInCurrentFiat!
        }
        
        // calculate lamports
        var lamports = amount.toLamport(decimals: wallet.token.decimals)
        if lamports > totalLamports {
            lamports = totalLamports
        }
        
        amountInLamportsSubject.accept(lamports)
    }
}
