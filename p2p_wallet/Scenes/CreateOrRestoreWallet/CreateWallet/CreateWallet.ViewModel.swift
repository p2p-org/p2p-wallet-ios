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
    var navigatableSceneDriver: Driver<CreateWallet.NavigatableScene?> { get }
    
    func kickOff()
    func verifyPhrase(_ phrases: [String])
    func handlePhrases(_ phrases: [String])
    func handleName(_ name: String?)
    func finish()

    func navigateToCreatePhrases()
    func navigateToReserveName(owner: String)
    func back()
}

extension CreateWallet {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var handler: CreateOrRestoreWalletHandler
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var notificationsService: NotificationsServiceType
        
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
        navigateToExplanation()
    }
    
    func verifyPhrase(_ phrases: [String]) {
        navigationSubject.accept(.verifyPhrase(phrases))
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
                DispatchQueue.main.async { [weak self] in
                    UIApplication.shared.hideHud()
                    self?.notificationsService.showToast(.error(error))
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

    func navigateToExplanation() {
        navigationSubject.accept(.explanation)
    }
    
    func dismiss() {
        navigationSubject.accept(.dismiss)
        navigationSubject.accept(.none)
    }
    
    func back() {
        navigationSubject.accept(.back)
        navigationSubject.accept(.none)
    }
    
    func navigateToCreatePhrases() {
        analyticsManager.log(event: .createWalletOpen)
        navigationSubject.accept(.createPhrases)
    }
    
    func navigateToReserveName(owner: String) {
        navigationSubject.accept(.reserveName(owner: owner))
    }
}
