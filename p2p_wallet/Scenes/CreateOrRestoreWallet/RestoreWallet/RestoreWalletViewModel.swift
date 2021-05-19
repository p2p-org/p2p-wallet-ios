//
//  RestoreWalletViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import UIKit
import RxSwift
import RxCocoa

enum RestoreWalletNavigatableScene {
    case enterPhrases
    case derivableAccounts(phrases: [String])
    case welcomeBack(phrases: [String], derivablePath: SolanaSDK.DerivablePath)
}

class RestoreWalletViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let bag = DisposeBag()
    let accountStorage: KeychainAccountStorage
    let handler: CreateOrRestoreWalletHandler
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<RestoreWalletNavigatableScene>()
    let errorMessage = PublishSubject<String?>()
    
    // MARK: - Initializer
    init(accountStorage: KeychainAccountStorage, handler: CreateOrRestoreWalletHandler) {
        self.accountStorage = accountStorage
        self.handler = handler
    }
    
    func finish() {
        handler.creatingOrRestoringWalletDidComplete()
    }
    
    // MARK: - Actions
    @objc func restoreFromICloud() {
        guard let phrases = accountStorage.phrasesFromICloud() else
        {
            errorMessage.onNext(L10n.thereIsNoP2PWalletSavedInYourICloud)
            return
        }
        handlePhrases(phrases.components(separatedBy: " "))
    }
    
    @objc func restoreManually() {
        navigationSubject.onNext(.enterPhrases)
    }
}

extension RestoreWalletViewModel: PhrasesCreationHandler {
    func handlePhrases(_ phrases: [String]) {
        navigationSubject.onNext(.derivableAccounts(phrases: phrases))
    }
}

extension RestoreWalletViewModel: CreateDerivableAccountHandler {
    func createDerivableAccount(phrases: [String], derivablePath: SolanaSDK.DerivablePath) {
        navigationSubject.onNext(.welcomeBack(phrases: phrases, derivablePath: derivablePath))
    }
}
