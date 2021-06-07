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
    
    // MARK: - Subjects
    let phrasesSubject = BehaviorRelay<[String]>(value: [])
    let errorSubject = PublishSubject<String>()
    
    // MARK: - Input
    let checkBoxIsSelectedInput = BehaviorRelay<Bool>(value: false)
    
    init(accountStorage: KeychainAccountStorage, createWalletViewModel: CreateWalletViewModel) {
        self.accountStorage = accountStorage
        self.createWalletViewModel = createWalletViewModel
        createPhrases()
    }
    
    // MARK: - Actions
    @objc func createPhrases() {
        let mnemonic = Mnemonic()
        phrasesSubject.accept(mnemonic.phrase)
        checkBoxIsSelectedInput.accept(false)
    }
    
    @objc func copyToClipboard() {
        UIApplication.shared.copyToClipboard(phrasesSubject.value.joined(separator: " "))
    }
    
    @objc func saveToICloud() {
        accountStorage.saveICloud(phrases: phrasesSubject.value.joined(separator: " "))
        UIApplication.shared.showDone(L10n.savedToICloud)
    }
    
    @objc func next() {
        do {
            try accountStorage.save(seedPhrases: self.phrasesSubject.value)
            let derivablePath = SolanaSDK.DerivablePath.default
            try accountStorage.save(derivableType: derivablePath.type)
            try accountStorage.save(selectedWalletIndex: derivablePath.walletIndex)
            createWalletViewModel.finish()
        } catch {
            self.errorSubject.onNext((error as? SolanaSDK.Error)?.errorDescription ?? error.localizedDescription)
        }
    }
}
