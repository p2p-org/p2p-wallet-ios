//
//  Root.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation
import RxSwift
import RxCocoa
import RxAppState

extension Root {
    class ViewModel: ViewModelType, ChangeNetworkResponder, ChangeLanguageResponder {
        // MARK: - Nested type
        struct Input {
            
        }
        struct Output {
            let navigationScene: Driver<NavigatableScene?>
            let isLoading: Driver<Bool>
        }
        
        // MARK: - Dependencies
        private let accountStorage: KeychainAccountStorage
        private let analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        private var isRestoration = false
        private var showAuthenticationOnMainOnAppear = true
        
        let input: Input
        private(set) var output: Output
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let isLoadingSubject = BehaviorRelay<Bool>(value: false)
        
        // MARK: - Initializer
        init(accountStorage: KeychainAccountStorage, analyticsManager: AnalyticsManagerType) {
            self.accountStorage = accountStorage
            self.analyticsManager = analyticsManager
            
            self.input = Input()
            self.output = Output(
                navigationScene: navigationSubject
                    .asDriver(),
                isLoading: isLoadingSubject
                    .asDriver()
            )
            
            bind()
        }
        
        /// Bind subjects
        private func bind() {
            bindInputIntoSubjects()
            bindSubjectsIntoSubjects()
        }
        
        private func bindInputIntoSubjects() {
            
        }
        
        private func bindSubjectsIntoSubjects() {
            
        }
        
        // MARK: - Actions
        func reload() {
            isLoadingSubject.accept(true)
            
            DispatchQueue.global(qos: .userInteractive).async {
                let account = self.accountStorage.account
                DispatchQueue.main.async {
                    if account == nil {
                        self.showAuthenticationOnMainOnAppear = false
                        self.navigationSubject.accept(.createOrRestoreWallet)
                    } else if self.accountStorage.pinCode == nil ||
                                !Defaults.didSetEnableBiometry ||
                                !Defaults.didSetEnableNotifications
                    {
                        self.showAuthenticationOnMainOnAppear = false
                        self.navigationSubject.accept(.onboarding)
                    } else {
                        self.navigationSubject.accept(.main(showAuthenticationWhenAppears: self.showAuthenticationOnMainOnAppear))
                    }
                }
            }
        }
        
        func logout() {
            accountStorage.clear()
            Defaults.walletName = [:]
            Defaults.didSetEnableBiometry = false
            Defaults.didSetEnableNotifications = false
            Defaults.didBackupOffline = false
            Defaults.renVMSession = nil
            Defaults.renVMSubmitedTxDetail = []
            reload()
        }
        
        @objc func finishSetup() {
            reload()
        }
        
        // MARK: - Responder
        func changeAPIEndpoint(to endpoint: SolanaSDK.APIEndPoint) {
            Defaults.apiEndPoint = endpoint
            
            showAuthenticationOnMainOnAppear = false
            reload()
        }
        
        func languageDidChange(to language: LocalizedLanguage) {
            UIApplication.changeLanguage(to: language)
            analyticsManager.log(event: .settingsLanguageSelected(language: language.code))
            
            showAuthenticationOnMainOnAppear = false
            reload()
        }
    }
}

extension Root.ViewModel: CreateOrRestoreWalletHandler {
    func creatingWalletDidComplete() {
        self.isRestoration = false
        navigationSubject.accept(.onboarding)
        analyticsManager.log(event: .setupOpen(fromPage: "create_wallet"))
    }
    
    func restoringWalletDidComplete() {
        self.isRestoration = true
        navigationSubject.accept(.onboarding)
        analyticsManager.log(event: .setupOpen(fromPage: "recovery"))
    }
    
    func creatingOrRestoringWalletDidCancel() {
        logout()
    }
}

extension Root.ViewModel: OnboardingHandler {
    func onboardingDidCancel() {
        logout()
    }
    
    @objc func onboardingDidComplete() {
        navigationSubject.accept(.onboardingDone(isRestoration: isRestoration))
    }
}
