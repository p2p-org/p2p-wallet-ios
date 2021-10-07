//
//  CreateWallet.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import UIKit
import RxSwift
import RxCocoa

protocol CreateWalletViewModelType: ReserveNameHandler {
    var navigatableSceneDriver: Driver<CreateWallet.NavigatableScene?> {get}
    
    func kickOff()
    func handlePhrases(_ phrases: [String])
    func handleName(_ name: String?)
    func finish()
    
    func navigateToTermsAndCondition()
    func declineTermsAndCondition()
    func acceptTermsAndCondition()
    func navigateToCreatePhrases()
    func navigateToReserveName(owner: String)
}

extension CreateWallet {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var handler: CreateOrRestoreWalletHandler
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var accountStorage: KeychainAccountStorage
        
        // MARK: - Properties
        private let bag = DisposeBag()
        private var phrases: [String]?
        private var name: String?
        
        // MARK: - Subjects
        private let navigationSubject = BehaviorRelay<CreateWallet.NavigatableScene?>(value: nil)
    }
}

extension CreateWallet.ViewModel: CreateWalletViewModelType {
    var navigatableSceneDriver: Driver<CreateWallet.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    // MARK: - Actions
    func kickOff() {
        navigateToCreatePhrases()
        // TODO: - Terms and condition
//        if !Defaults.isTermAndConditionsAccepted {
//            navigateToTermsAndCondition()
//        } else {
//            navigateToCreatePhrases()
//        }
    }
    
    func handlePhrases(_ phrases: [String]) {
        self.phrases = phrases
        
        UIApplication.shared.showIndetermineHud()
        DispatchQueue.global().async { [weak self] in
            do {
                // create wallet
                let account = try SolanaSDK.Account(phrase: phrases, network: Defaults.apiEndPoint.network, derivablePath: .default)
                
                DispatchQueue.main.async { [weak self] in
                    UIApplication.shared.hideHud()
                    self?.navigateToReserveName(owner: account.publicKey.base58EncodedString)
                }
            } catch {
                DispatchQueue.main.async {
                    UIApplication.shared.hideHud()
                    UIApplication.shared.showToast(message: (error as? SolanaSDK.Error)?.errorDescription ?? error.localizedDescription)
                }
            }
        }
    }
    
    func handleName(_ name: String?) {
        self.name = name
        finish()
    }
    
    func finish() {
        navigationSubject.accept(.dismiss)
        handler.creatingWalletDidComplete(
            phrases: phrases,
            derivablePath: .default,
            name: name
        )
    }
    
    func navigateToTermsAndCondition() {
        navigationSubject.accept(.termsAndConditions)
    }
    
    func declineTermsAndCondition() {
        navigationSubject.accept(.dismiss)
    }
    
    func acceptTermsAndCondition() {
        Defaults.isTermAndConditionsAccepted = true
        navigateToCreatePhrases()
    }
    
    func navigateToCreatePhrases() {
        analyticsManager.log(event: .createWalletOpen)
        navigationSubject.accept(.createPhrases)
    }
    
    func navigateToReserveName(owner: String) {
        navigationSubject.accept(.reserveName(owner: owner))
    }
}
