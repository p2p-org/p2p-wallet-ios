//
//  CreateSecurityKeysViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/02/2021.
//

import UIKit
import RxSwift
import RxCocoa

class CreateSecurityKeysViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    let accountStorage: KeychainAccountStorage
    let createWalletViewModel: CreateWalletViewModel
    let analyticsManager: AnalyticsManagerType
    
    // MARK: - Subjects
    let phrasesSubject = BehaviorRelay<[String]>(value: [])
    let errorSubject = PublishSubject<String>()
    
    // MARK: - Input
    let checkBoxIsSelectedInput = BehaviorRelay<Bool>(value: false)
    
    init(accountStorage: KeychainAccountStorage, createWalletViewModel: CreateWalletViewModel, analyticsManager: AnalyticsManagerType) {
        self.accountStorage = accountStorage
        self.createWalletViewModel = createWalletViewModel
        self.analyticsManager = analyticsManager
        createPhrases()
    }
    
    // MARK: - Actions
    @objc func createPhrases() {
        let mnemonic = Mnemonic()
        phrasesSubject.accept(mnemonic.phrase)
        checkBoxIsSelectedInput.accept(false)
    }
    
    @objc func copyToClipboard() {
        analyticsManager.log(event: .createWalletCopySeedClick)
        UIApplication.shared.copyToClipboard(phrasesSubject.value.joined(separator: " "), alertMessage: L10n.seedPhraseCopiedToClipboard)
    }
    
    @objc func saveToICloud() {
        analyticsManager.log(event: .createWalletBackupToIcloudClick)
        accountStorage.saveICloud(phrases: phrasesSubject.value.joined(separator: " "))
        UIApplication.shared.showToast(message: "✅ " + L10n.savedToICloud)
    }
    
    @objc func next() {
        if checkBoxIsSelectedInput.value {
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
                    self.errorSubject.onNext((error as? SolanaSDK.Error)?.errorDescription ?? error.localizedDescription)
                }
            }
        }
    }
}
