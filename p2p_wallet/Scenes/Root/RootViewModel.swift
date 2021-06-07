//
//  RootViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import UIKit
import RxSwift
import RxCocoa
import RxAppState

enum RootNavigatableScene: Equatable {
    case initializing
    case createOrRestoreWallet
    case onboarding
    case onboardingDone(isRestoration: Bool)
    case main
    case resetPincodeWithASeedPhrase
}

protocol CreateOrRestoreWalletHandler {
    func creatingWalletDidComplete()
    func restoringWalletDidComplete()
    func creatingOrRestoringWalletDidCancel()
}

protocol OnboardingHandler {
    func onboardingDidCancel()
    func onboardingDidComplete()
}

class RootViewModel: CreateOrRestoreWalletHandler, OnboardingHandler, AuthenticationHandler {
    // MARK: - Constants
    private var timeRequiredForAuthentication = 10 // in seconds
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let accountStorage: KeychainAccountStorage
    
    private(set) var isAuthenticating = false
    private var isRestoration = false
    lazy var lastAuthenticationTimestamp = Int(Date().timeIntervalSince1970) - timeRequiredForAuthentication
    
    var isSessionExpired: Bool {
        Int(Date().timeIntervalSince1970) >= lastAuthenticationTimestamp + timeRequiredForAuthentication
    }
    
    var didResetPinCodeWithSeedPhrases = false
    
    // MARK: - Subjects
    let navigationSubject = BehaviorRelay<RootNavigatableScene>(value: .initializing)
    let authenticationSubject = PublishSubject<AuthenticationPresentationStyle>()
    let loadingSubject = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Methods
    init(accountStorage: KeychainAccountStorage) {
        self.accountStorage = accountStorage
        observeAppNotifications()
    }
    
    func reload() {
        // loading
        loadingSubject.accept(true)
        
        accountStorage.getCurrentAccount()
            .subscribe(onSuccess: {[weak self] account in
                self?.loadingSubject.accept(false)
                
                if account == nil {
                    self?.navigationSubject.accept(.createOrRestoreWallet)
                } else if self?.accountStorage.pinCode == nil ||
                            !Defaults.didSetEnableBiometry ||
                            !Defaults.didSetEnableNotifications
                {
                    self?.navigationSubject.accept(.onboarding)
                } else {
                    self?.navigationSubject.accept(.main)
                }
            })
            .disposed(by: disposeBag)
        
    }
    
    func logout() {
        accountStorage.clear()
        Defaults.walletName = [:]
        Defaults.didSetEnableBiometry = false
        Defaults.didSetEnableNotifications = false
        reload()
    }
    
    // MARK: - Handler
    func creatingWalletDidComplete() {
        self.isRestoration = false
        navigationSubject.accept(.onboarding)
    }
    
    func restoringWalletDidComplete() {
        self.isRestoration = true
        navigationSubject.accept(.onboarding)
    }
    
    func creatingOrRestoringWalletDidCancel() {
        logout()
    }
    
    func onboardingDidCancel() {
        logout()
    }
    
    @objc func onboardingDidComplete() {
        navigationSubject.accept(.onboardingDone(isRestoration: isRestoration))
    }
    
    @objc func navigateToMain() {
        navigationSubject.accept(.main)
    }
    
    func authenticate(presentationStyle: AuthenticationPresentationStyle) {
        authenticationSubject.onNext(presentationStyle)
    }
    
    @objc func resetPinCodeWithASeedPhrase() {
        navigationSubject.accept(.resetPincodeWithASeedPhrase)
    }
    
    func observeAppNotifications() {
        UIApplication.shared.rx.applicationDidBecomeActive
            .subscribe(onNext: {[weak self] _ in
                guard let strongSelf = self, !strongSelf.isAuthenticating, strongSelf.isSessionExpired
                else {return}
                strongSelf.authenticationSubject
                    .onNext(
                        AuthenticationPresentationStyle(
                            isRequired: true,
                            isFullScreen: true,
                            useBiometry: true,
                            completion: nil
                        )
                    )
            })
            .disposed(by: disposeBag)
    }
    
    func secondsLeftToNextAuthentication() -> Int {
        timeRequiredForAuthentication - (Int(Date().timeIntervalSince1970) - Int(lastAuthenticationTimestamp))
    }
    
    func markAsIsAuthenticating(_ bool: Bool = true) {
        isAuthenticating = bool
    }
}
