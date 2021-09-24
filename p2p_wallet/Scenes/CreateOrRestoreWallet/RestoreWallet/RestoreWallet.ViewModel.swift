//
//  RestoreWallet.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import UIKit
import RxSwift
import RxCocoa

protocol RestoreWalletViewModelType {
    var navigatableSceneDriver: Driver<RestoreWallet.NavigatableScene?> {get}
    var errorSignal: Signal<String> {get}
    
    func handlePhrases(_ phrases: [String])
    func restoreFromICloud()
    func restoreManually()
}

extension RestoreWallet {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var accountStorage: KeychainAccountStorage
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var handler: CreateOrRestoreWalletHandler
        
        // MARK: - Properties
        private let bag = DisposeBag()
        private var phrases: [String]?
        
        // MARK: - Subjects
        private let navigationSubject = BehaviorRelay<RestoreWallet.NavigatableScene?>(value: nil)
        private let errorSubject = PublishRelay<String>()
    }
}

extension RestoreWallet.ViewModel: RestoreWalletViewModelType {
    var navigatableSceneDriver: Driver<RestoreWallet.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var errorSignal: Signal<String> {
        errorSubject.asSignal()
    }
    
    // MARK: - Actions
    func restoreFromICloud() {
        guard let phrases = accountStorage.phrasesFromICloud() else
        {
            errorSubject.accept(L10n.thereIsNoP2PWalletSavedInYourICloud)
            return
        }
        analyticsManager.log(event: .recoveryRestoreIcloudClick)
        handlePhrases(phrases.components(separatedBy: " "))
    }
    
    func restoreManually() {
        analyticsManager.log(event: .recoveryRestoreManualyClick)
        navigationSubject.accept(.enterPhrases)
    }
    
    func handlePhrases(_ phrases: [String]) {
        self.phrases = phrases
        navigationSubject.accept(.derivableAccounts(phrases: phrases))
    }
}

extension RestoreWallet.ViewModel: AccountRestorationHandler {
    func derivablePathDidSelect(_ derivablePath: SolanaSDK.DerivablePath) {
        analyticsManager.log(event: .recoveryRestoreClick)
        
        do {
            guard let phrases = self.phrases else {
                handler.creatingOrRestoringWalletDidCancel()
                return
            }
            try accountStorage.save(phrases: phrases)
            try accountStorage.save(derivableType: derivablePath.type)
            try accountStorage.save(walletIndex: derivablePath.walletIndex)
            
            handler.restoringWalletDidComplete()
        } catch {
            errorSubject.accept(error.readableDescription)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.handler.creatingOrRestoringWalletDidCancel()
            }
        }
    }
}
