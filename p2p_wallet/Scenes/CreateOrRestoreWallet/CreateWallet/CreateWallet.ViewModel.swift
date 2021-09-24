//
//  CreateWallet.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import UIKit
import RxSwift
import RxCocoa

protocol CreateWalletViewModelType {
    var navigatableSceneDriver: Driver<CreateWallet.NavigatableScene?> {get}
    
    func kickOff()
    func finish()
    
    func navigateToTermsAndCondition()
    func declineTermsAndCondition()
    func acceptTermsAndCondition()
    func navigateToCreatePhrases()
}

extension CreateWallet {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var handler: CreateOrRestoreWalletHandler
        @Injected private var analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        private let bag = DisposeBag()
        
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
        if !Defaults.isTermAndConditionsAccepted {
            navigateToTermsAndCondition()
        } else {
            navigateToCreatePhrases()
        }
    }
    
    func finish() {
        navigationSubject.accept(.dismiss)
        handler.creatingWalletDidComplete()
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
}
