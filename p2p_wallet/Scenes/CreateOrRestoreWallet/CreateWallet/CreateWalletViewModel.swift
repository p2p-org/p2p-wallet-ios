//
//  CreateWalletViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import UIKit
import RxSwift
import RxCocoa

enum CreateWalletNavigatableScene {
    case termsAndConditions
    case createPhrases
    case dismiss
}

class CreateWalletViewModel: ViewModelType {
    // MARK: - Nested types
    struct Input {}
    struct Output {
        let navigation: Driver<CreateWalletNavigatableScene>
    }
    
    // MARK: - Dependencies
    private let handler: CreateOrRestoreWalletHandler
    private let analyticsManager: AnalyticsManagerType
    
    // MARK: - Properties
    private let bag = DisposeBag()
    let input: Input
    let output: Output
    
    // MARK: - Subjects
    private let navigationSubject = PublishSubject<CreateWalletNavigatableScene>()
    
    init(handler: CreateOrRestoreWalletHandler, analyticsManager: AnalyticsManagerType) {
        self.analyticsManager = analyticsManager
        self.handler = handler
        
        self.input = Input()
        self.output = Output(
            navigation: navigationSubject.asDriver(onErrorJustReturn: .termsAndConditions)
        )
    }
    
    func kickOff() {
        if !Defaults.isTermAndConditionsAccepted {
            navigateToTermsAndCondition()
        } else {
            navigateToCreatePhrases()
        }
    }
    
    func finish() {
        navigationSubject.onNext(.dismiss)
        handler.creatingWalletDidComplete()
    }
    
    // MARK: - Actions
    @objc func navigateToTermsAndCondition() {
        navigationSubject.onNext(.termsAndConditions)
    }
    
    @objc func declineTermsAndCondition() {
        navigationSubject.onNext(.dismiss)
    }
    
    @objc func acceptTermsAndCondition() {
        Defaults.isTermAndConditionsAccepted = true
        navigateToCreatePhrases()
    }
    
    @objc func navigateToCreatePhrases() {
        analyticsManager.log(event: .signupOpen)
        navigationSubject.onNext(.createPhrases)
    }
}
