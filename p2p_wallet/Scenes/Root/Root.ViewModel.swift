//
//  Root.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol RootViewModelType {
    var navigationSceneDriver: Driver<Root.NavigatableScene?> {get}
    var isLoadingDriver: Driver<Bool> {get}
    
    func reload()
    func logout()
    func finishSetup()
}

protocol CreateOrRestoreWalletHandler {
    func creatingWalletDidComplete()
    func restoringWalletDidComplete()
    func creatingOrRestoringWalletDidCancel()
}

extension Root {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var accountStorage: KeychainAccountStorage
        @Injected private var analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        private var isRestoration = false
        private var showAuthenticationOnMainOnAppear = true
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let isLoadingSubject = BehaviorRelay<Bool>(value: false)
        
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
    }
}

extension Root.ViewModel: RootViewModelType {
    var navigationSceneDriver: Driver<Root.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var isLoadingDriver: Driver<Bool> {
        isLoadingSubject.asDriver()
    }
}

extension Root.ViewModel: ChangeNetworkResponder {
    func changeAPIEndpoint(to endpoint: SolanaSDK.APIEndPoint) {
        Defaults.apiEndPoint = endpoint
        
        showAuthenticationOnMainOnAppear = false
        reload()
    }
}

extension Root.ViewModel: ChangeLanguageResponder {
    func languageDidChange(to language: LocalizedLanguage) {
        UIApplication.changeLanguage(to: language)
        analyticsManager.log(event: .settingsLanguageSelected(language: language.code))
        
        showAuthenticationOnMainOnAppear = false
        reload()
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
