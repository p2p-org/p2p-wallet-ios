//
//  RestoreWallet.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import UIKit
import RxSwift
import RxCocoa

protocol RestoreWalletViewModelType: ReserveNameHandler {
    var navigatableSceneDriver: Driver<RestoreWallet.NavigatableScene?> {get}
    var isLoadingDriver: Driver<Bool> {get}
    var errorSignal: Signal<String> {get}
    
    func handlePhrases(_ phrases: [String])
    func handleICloudAccount(_ account: Account)
    func restoreFromICloud()
    func restoreManually()
}

extension RestoreWallet {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var accountStorage: KeychainAccountStorage
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var handler: CreateOrRestoreWalletHandler
        @Injected private var nameService: NameServiceType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        private var phrases: [String]?
        private var derivablePath: SolanaSDK.DerivablePath?
        private var name: String?
        
        // MARK: - Subjects
        private let navigationSubject = BehaviorRelay<RestoreWallet.NavigatableScene?>(value: nil)
        private let isLoadingSubject = BehaviorRelay<Bool>(value: false)
        private let errorSubject = PublishRelay<String>()
    }
}

extension RestoreWallet.ViewModel: RestoreWalletViewModelType {
    var navigatableSceneDriver: Driver<RestoreWallet.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var isLoadingDriver: Driver<Bool> {
        isLoadingSubject.asDriver()
    }
    
    var errorSignal: Signal<String> {
        errorSubject.asSignal()
    }
    
    // MARK: - Actions
    func restoreFromICloud() {
        guard let accounts = accountStorage.accountFromICloud(), accounts.count > 0
        else {
            errorSubject.accept(L10n.thereIsNoP2PWalletSavedInYourICloud)
            return
        }
        analyticsManager.log(event: .recoveryRestoreIcloudClick)
        
        // if there is only 1 account saved in iCloud
        if accounts.count == 1 {
            handlePhrases(accounts[0].phrase.components(separatedBy: " "))
            return
        }
        
        // if there are more than 1 account saved in iCloud
        navigationSubject.accept(.restoreFromICloud)
    }
    
    func restoreManually() {
        analyticsManager.log(event: .recoveryRestoreManualyClick)
        navigationSubject.accept(.enterPhrases)
    }
    
    func handlePhrases(_ phrases: [String]) {
        self.phrases = phrases
        navigationSubject.accept(.derivableAccounts(phrases: phrases))
    }
    
    func handleICloudAccount(_ account: Account) {
        self.phrases = account.phrase.components(separatedBy: " ")
        self.derivablePath = account.derivablePath
        if let name = account.name {
            self.name = name
            finish()
        } else {
            // create account
            isLoadingSubject.accept(true)
            DispatchQueue(label: "Create account", qos: .userInteractive).async { [unowned self] in
                guard let phrases = self.phrases else {return}
                do {
                    let account = try SolanaSDK.Account(phrase: phrases, network: Defaults.apiEndPoint.network, derivablePath: derivablePath)
                    DispatchQueue.main.async { [weak self] in
                        // reserve name
                        self?.isLoadingSubject.accept(false)
                        self?.navigationSubject.accept(.reserveName(owner: account.publicKey.base58EncodedString))
                    }
                } catch {
                    self.errorSubject.accept(error.readableDescription)
                }
            }
        }
    }
}

extension RestoreWallet.ViewModel: AccountRestorationHandler {
    func derivablePathDidSelect(_ derivablePath: SolanaSDK.DerivablePath) {
        analyticsManager.log(event: .recoveryRestoreClick)
        self.derivablePath = derivablePath
        
        // create account
        isLoadingSubject.accept(true)
        DispatchQueue(label: "Create account", qos: .userInteractive).async { [unowned self] in
            guard let phrases = self.phrases else {return}
            do {
                let account = try SolanaSDK.Account(phrase: phrases, network: Defaults.apiEndPoint.network, derivablePath: derivablePath)
                DispatchQueue.main.async { [weak self] in
                    self?.checkIfNameIsReservedAndReserveNameIfNeeded(owner: account.publicKey.base58EncodedString)
                }
            } catch {
                self.errorSubject.accept(error.readableDescription)
            }
        }
    }
    
    private func checkIfNameIsReservedAndReserveNameIfNeeded(owner: String) {
        nameService.getName(owner)
            .subscribe(onSuccess: {[weak self] names in
                self?.isLoadingSubject.accept(false)
                if !names.isEmpty {
                    self?.handleName(names.first?.name)
                } else {
                    self?.navigationSubject.accept(.reserveName(owner: owner))
                }
            }, onFailure: {[weak self] _ in
                self?.isLoadingSubject.accept(false)
                self?.navigationSubject.accept(.reserveName(owner: owner))
            })
            .disposed(by: disposeBag)
    }
}

extension RestoreWallet.ViewModel: ReserveNameHandler {
    func handleName(_ name: String?) {
        self.name = name
        finish()
    }
}

private extension RestoreWallet.ViewModel {
    func finish() {
        guard let derivablePath = derivablePath else {return}
        
        do {
            guard let phrases = self.phrases else {
                handler.creatingOrRestoringWalletDidCancel()
                return
            }
            try accountStorage.save(phrases: phrases)
            try accountStorage.save(derivableType: derivablePath.type)
            try accountStorage.save(walletIndex: derivablePath.walletIndex)
            if let name = self.name {
                accountStorage.save(name: name)
            }
            
            handler.restoringWalletDidComplete()
        } catch {
            errorSubject.accept(error.readableDescription)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.handler.creatingOrRestoringWalletDidCancel()
            }
        }
    }
}
