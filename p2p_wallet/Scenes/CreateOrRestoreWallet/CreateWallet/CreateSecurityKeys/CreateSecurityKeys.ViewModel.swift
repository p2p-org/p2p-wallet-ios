//
//  CreateSecurityKeys.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/02/2021.
//

import UIKit
import RxSwift
import RxCocoa

protocol CreateSecurityKeysViewModelType {
    var phrasesDriver: Driver<[String]> {get}
    var errorSignal: Signal<String> {get}
    var isCheckboxSelectedDriver: Driver<Bool> {get}
    
    func toggleCheckbox(selected: Bool)
    func createPhrases()
    func copyToClipboard()
    func saveToICloud()
    func next()
}

extension CreateSecurityKeys {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var accountStorage: KeychainAccountStorage
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var createWalletViewModel: CreateWalletViewModelType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        
        // MARK: - Subjects
        private let phrasesSubject = BehaviorRelay<[String]>(value: [])
        private let errorSubject = PublishRelay<String>()
        private let isCheckboxSelectedSubject = BehaviorRelay<Bool>(value: false)
        
        // MARK: - Initializer
        init() {
            createPhrases()
        }
    }
}

extension CreateSecurityKeys.ViewModel: CreateSecurityKeysViewModelType {
    var phrasesDriver: Driver<[String]> {
        phrasesSubject.asDriver()
    }
    
    var errorSignal: Signal<String> {
        errorSubject.asSignal()
    }
    
    var isCheckboxSelectedDriver: Driver<Bool> {
        isCheckboxSelectedSubject.asDriver()
    }
    
    // MARK: - Actions
    func toggleCheckbox(selected: Bool) {
        isCheckboxSelectedSubject.accept(selected)
    }
    
    func createPhrases() {
        let mnemonic = Mnemonic()
        phrasesSubject.accept(mnemonic.phrase)
        isCheckboxSelectedSubject.accept(false)
    }
    
    @objc func copyToClipboard() {
        analyticsManager.log(event: .createWalletCopySeedClick)
        UIApplication.shared.copyToClipboard(phrasesSubject.value.joined(separator: " "), alertMessage: L10n.seedPhraseCopiedToClipboard)
    }
    
    @objc func saveToICloud() {
        analyticsManager.log(event: .createWalletBackupToIcloudClick)
        accountStorage.saveToICloud(
            account: .init(
                phrase: phrasesSubject.value.joined(separator: " "),
                derivablePath: .default
            )
        )
        UIApplication.shared.showToast(message: "✅ " + L10n.savedToICloud)
    }
    
    @objc func next() {
        if isCheckboxSelectedSubject.value {
            analyticsManager.log(event: .createWalletIHaveSavedWordsClick)
        }
        analyticsManager.log(event: .createWalletNextClick)
        
        UIApplication.shared.showIndetermineHud()
        DispatchQueue.global().async {
            do {
                try self.accountStorage.save(phrases: self.phrasesSubject.value)
                
                let derivablePath = SolanaSDK.DerivablePath.default
                try self.accountStorage.save(derivableType: derivablePath.type)
                try self.accountStorage.save(walletIndex: derivablePath.walletIndex)
                
                DispatchQueue.main.async {
                    UIApplication.shared.hideHud()
                    self.createWalletViewModel.finish()
                }
            } catch {
                DispatchQueue.main.async {
                    UIApplication.shared.hideHud()
                    self.errorSubject.accept((error as? SolanaSDK.Error)?.errorDescription ?? error.localizedDescription)
                }
            }
        }
    }
}
