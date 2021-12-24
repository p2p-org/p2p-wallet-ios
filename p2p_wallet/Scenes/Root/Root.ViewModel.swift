//
//  Root.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation
import RxSwift
import RxCocoa
import Resolver

protocol RootViewModelType {
    var navigationSceneDriver: Driver<Root.NavigatableScene?> {get}
    var isLoadingDriver: Driver<Bool> {get}
    
    func reload()
    func logout()
    func finishSetup()
}

protocol CreateOrRestoreWalletHandler {
    func creatingWalletDidComplete(phrases: [String]?, derivablePath: SolanaSDK.DerivablePath?, name: String?)
    func restoringWalletDidComplete(phrases: [String]?, derivablePath: SolanaSDK.DerivablePath?, name: String?)
    func creatingOrRestoringWalletDidCancel()
}

extension Root {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var storage: AccountStorageType & PincodeStorageType & NameStorageType
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var notificationsService: NotificationsServiceType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        private var isRestoration = false
        private var showAuthenticationOnMainOnAppear = true
        private var resolvedName: String?
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let isLoadingSubject = BehaviorRelay<Bool>(value: false)
        
        // MARK: - Actions
        func reload() {
            isLoadingSubject.accept(true)
            
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                let account = self?.storage.account
                DispatchQueue.main.async { [weak self] in
                    if account == nil {
                        self?.showAuthenticationOnMainOnAppear = false
                        self?.navigationSubject.accept(.createOrRestoreWallet)
                    } else if self?.storage.pinCode == nil ||
                                !Defaults.didSetEnableBiometry ||
                                !Defaults.didSetEnableNotifications
                    {
                        self?.showAuthenticationOnMainOnAppear = false
                        self?.navigationSubject.accept(.onboarding)
                    } else {
                        self?.navigationSubject.accept(.main(showAuthenticationWhenAppears: self?.showAuthenticationOnMainOnAppear ?? false))
                    }
                }
            }
        }
        
        func logout() {
            ResolverScope.session.reset()
            storage.clearAccount()
            Defaults.walletName = [:]
            Defaults.didSetEnableBiometry = false
            Defaults.didSetEnableNotifications = false
            Defaults.didBackupOffline = false
            Defaults.renVMSession = nil
            Defaults.renVMProcessingTxs = []
            Defaults.forceCloseNameServiceBanner = false
            Defaults.shouldShowConfirmAlertOnSend = true
            Defaults.shouldShowConfirmAlertOnSwap = true
            reload()
        }
        
        @objc func finishSetup() {
            analyticsManager.log(event: .setupFinishClick)
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
        ResolverScope.session.reset()
        reload()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.notificationsService.showInAppNotification(.done(L10n.networkChanged))
        }
    }
}

extension Root.ViewModel: ChangeLanguageResponder {
    func languageDidChange(to language: LocalizedLanguage) {
        UIApplication.languageChanged()
        analyticsManager.log(event: .settingsLanguageSelected(language: language.code))
        
        showAuthenticationOnMainOnAppear = false
        reload()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            let languageChangedText = language.originalName.map(L10n.changedLanguageTo) ?? L10n.interfaceLanguageChanged
            self?.notificationsService.showInAppNotification(.done(languageChangedText))
        }
    }
}

extension Root.ViewModel: CreateOrRestoreWalletHandler {
    func creatingWalletDidComplete(phrases: [String]?, derivablePath: SolanaSDK.DerivablePath?, name: String?) {
        isRestoration = false
        resolvedName = name
        navigationSubject.accept(.onboarding)
        analyticsManager.log(event: .setupOpen(fromPage: "create_wallet"))
        saveAccountToStorage(phrases: phrases, derivablePath: derivablePath, name: name)
    }
    
    func restoringWalletDidComplete(phrases: [String]?, derivablePath: SolanaSDK.DerivablePath?, name: String?) {
        isRestoration = true
        resolvedName = name
        navigationSubject.accept(.onboarding)
        analyticsManager.log(event: .setupOpen(fromPage: "recovery"))
        saveAccountToStorage(phrases: phrases, derivablePath: derivablePath, name: name)
    }
    
    func creatingOrRestoringWalletDidCancel() {
        logout()
    }
    
    private func saveAccountToStorage(phrases: [String]?, derivablePath: SolanaSDK.DerivablePath?, name: String?) {
        guard let phrases = phrases, let derivablePath = derivablePath else {
            creatingOrRestoringWalletDidCancel()
            return
        }
        
        isLoadingSubject.accept(true)
        DispatchQueue.global().async { [weak self] in
            do {
                try self?.storage.save(phrases: phrases)
                try self?.storage.save(derivableType: derivablePath.type)
                try self?.storage.save(walletIndex: derivablePath.walletIndex)
                
                if let name = name {
                    self?.storage.save(name: name)
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.isLoadingSubject.accept(false)
                }
            } catch {
                self?.isLoadingSubject.accept(false)
                DispatchQueue.main.async { [weak self] in
                    self?.notificationsService.showInAppNotification(.error(error))
                    self?.creatingOrRestoringWalletDidCancel()
                }
            }
        }
    }
}

extension Root.ViewModel: OnboardingHandler {
    func onboardingDidCancel() {
        logout()
    }
    
    @objc func onboardingDidComplete() {
        let event: AnalyticsEvent = isRestoration ? .setupWelcomeBackOpen: .setupFinishOpen
        analyticsManager.log(event: event)
        navigationSubject.accept(.onboardingDone(isRestoration: isRestoration, name: resolvedName))
    }
}
