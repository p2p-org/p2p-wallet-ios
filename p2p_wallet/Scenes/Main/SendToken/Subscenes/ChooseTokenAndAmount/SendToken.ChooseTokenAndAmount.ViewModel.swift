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

protocol SendTokenChooseTokenAndAmountViewModelType: WalletDidSelectHandler, SendTokenTokenAndAmountHandler {
    var initialAmount: Double? {get}
    
    var navigationDriver: Driver<SendToken.ChooseTokenAndAmount.NavigatableScene?> {get}
    var currencyModeDriver: Driver<SendToken.ChooseTokenAndAmount.CurrencyMode> {get}
    var errorDriver: Driver<SendToken.ChooseTokenAndAmount.Error?> {get}
    var showAfterConfirmation: Bool {get}
    var selectedNetwork: SendToken.Network? {get}
    var canGoBack: Bool { get }
    
    func navigate(to scene: SendToken.ChooseTokenAndAmount.NavigatableScene)
    func cancelSending()
    func toggleCurrencyMode()
    
    func calculateAvailableAmount() -> Double?
    
    func isTokenValidForSelectedNetwork() -> Bool
    func save()
    func navigateNext()
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
        private let sendTokenViewModel: SendTokenViewModelType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        let showAfterConfirmation: Bool
        let initialAmount: Double?
        let selectedNetwork: SendToken.Network?
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let currencyModeSubject = BehaviorRelay<CurrencyMode>(value: .token)
        let walletSubject = BehaviorRelay<Wallet?>(value: nil)
        let amountSubject = BehaviorRelay<Double?>(value: nil)
        
        // MARK: - Initializer
        init(
            initialAmount: Double? = nil,
            showAfterConfirmation: Bool = false,
            selectedNetwork: SendToken.Network?,
            sendTokenViewModel: SendTokenViewModelType
        ) {
            self.initialAmount = initialAmount
            self.showAfterConfirmation = showAfterConfirmation
            self.selectedNetwork = selectedNetwork
            self.sendTokenViewModel = sendTokenViewModel
            bind()
        }
        
        private func bind() {
            #if DEBUG
            amountSubject.subscribe(onNext: {debugPrint($0 ?? 0)}).disposed(by: disposeBag)
            #endif
            
            sendTokenViewModel.walletDriver
                .drive(walletSubject)
                .disposed(by: disposeBag)
            
            sendTokenViewModel.amountDriver
                .drive(amountSubject)
                .disposed(by: disposeBag)
        }
    }
}

extension SendToken.ChooseTokenAndAmount.ViewModel: SendTokenChooseTokenAndAmountViewModelType {
    var canGoBack: Bool {
        sendTokenViewModel.canGoBack
    }

    var navigationDriver: Driver<SendToken.ChooseTokenAndAmount.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var currencyModeDriver: Driver<SendToken.ChooseTokenAndAmount.CurrencyMode> {
        currencyModeSubject.asDriver()
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
        if scene == .chooseWallet {
            analyticsManager.log(event: .tokenListViewed(lastScreen: "Send", tokenListLocation: "Token_A"))
        }
        navigationSubject.accept(scene)
    }
    
    func cancelSending() {
        sendTokenViewModel.navigate(to: .back)
    }
    
    func toggleCurrencyMode() {
        if currencyModeSubject.value == .token {
            currencyModeSubject.accept(.fiat)
        } else {
            currencyModeSubject.accept(.token)
        }
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
        debugPrint("availableAmount \(availableAmount)")
        #endif
        
        // return
        return availableAmount > 0 ? availableAmount: 0
    }
    
    func isTokenValidForSelectedNetwork() -> Bool {
        let isValid = selectedNetwork != .bitcoin || walletSubject.value?.token.isRenBTC == true
        if !isValid && showAfterConfirmation {
            navigationSubject.accept(.invalidTokenForSelectedNetworkAlert)
        }
        return isValid
    }
    
    func save() {
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
        
        sendTokenViewModel.chooseWallet(wallet)
        sendTokenViewModel.enterAmount(lamports.convertToBalance(decimals: wallet.token.decimals))
    }
    
    func navigateNext() {
        sendTokenViewModel.navigate(to: .chooseRecipientAndNetwork(showAfterConfirmation: showAfterConfirmation, preSelectedNetwork: nil))
    }
}
