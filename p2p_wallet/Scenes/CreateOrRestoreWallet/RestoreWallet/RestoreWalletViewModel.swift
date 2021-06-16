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
}

class RestoreWalletViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let bag = DisposeBag()
    let accountStorage: KeychainAccountStorage
    let handler: CreateOrRestoreWalletHandler
    let analyticsManager: AnalyticsManagerType
    
    private var phrases: [String]?
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<RestoreWalletNavigatableScene>()
    let errorMessage = PublishSubject<String?>()
    
    // MARK: - Initializer
    init(accountStorage: KeychainAccountStorage, handler: CreateOrRestoreWalletHandler, analyticsManager: AnalyticsManagerType) {
        self.accountStorage = accountStorage
        self.handler = handler
        self.analyticsManager = analyticsManager
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
        if self.phrases != phrases {
            analyticsManager.log(event: .loginSeedKeydown)
        }
        self.phrases = phrases
        navigationSubject.onNext(.derivableAccounts(phrases: phrases))
    }
}

extension RestoreWalletViewModel: AccountRestorationHandler {
    func derivablePathDidSelect(_ derivablePath: SolanaSDK.DerivablePath) {
        do {
            guard let phrases = self.phrases else {
                handler.creatingOrRestoringWalletDidCancel()
                return
            }
            try accountStorage.save(phrases: phrases)
            try accountStorage.save(derivableType: derivablePath.type)
            try accountStorage.save(walletIndex: derivablePath.walletIndex)
            
            analyticsManager.log(event: .loginContinueDerivationPathClick, params: ["derivationPath": derivablePath.rawValue])
            
            handler.restoringWalletDidComplete()
        } catch {
            errorMessage.onNext(error.readableDescription)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.handler.creatingOrRestoringWalletDidCancel()
            }
        }
    }
}
