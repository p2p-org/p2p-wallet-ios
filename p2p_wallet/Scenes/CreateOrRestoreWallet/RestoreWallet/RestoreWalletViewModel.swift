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
    case welcomeBack(phrases: [String])
}

class RestoreWalletViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let bag = DisposeBag()
    let completion: () -> Void
    let accountStorage: KeychainAccountStorage
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<RestoreWalletNavigatableScene>()
    let errorMessage = PublishSubject<String?>()
    
    // MARK: - Initializer
    init(accountStorage: KeychainAccountStorage, completion: @escaping () -> Void) {
        self.accountStorage = accountStorage
        self.completion = completion
    }
    
    func finish() {
        completion()
    }
    
    // MARK: - Actions
    @objc func restoreFromICloud() {
        guard let phrases = accountStorage.phrasesFromICloud() else
        {
            errorMessage.onNext(L10n.thereIsNoP2PWalletSavedInYourICloud)
            return
        }
        handlePhrases(phrases)
    }
    
    @objc func restoreManually() {
        navigationSubject.onNext(.enterPhrases)
    }
    
    private func handlePhrases(_ text: String)
    {
        do {
            let phrases = text.components(separatedBy: " ")
            _ = try Mnemonic(phrase: phrases.filter {!$0.isEmpty})
            navigationSubject.onNext(.welcomeBack(phrases: phrases))
        } catch {
            let message = (error as? SolanaSDK.Error)?.errorDescription ?? error.localizedDescription
            errorMessage.onNext(message)
        }
    }
}
