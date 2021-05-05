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
        UIApplication.shared.showIndetermineHud()
        DispatchQueue.global().async {
            do {
                let account = try SolanaSDK.Account(phrase: self.phrasesSubject.value, network: Defaults.apiEndPoint.network)
                try self.accountStorage.save(account)
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
