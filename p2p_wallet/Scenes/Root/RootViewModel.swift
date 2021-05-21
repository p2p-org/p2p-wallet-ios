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

struct AuthenticationPresentationStyle {
    var title: String = L10n.enterPINCode
    let isRequired: Bool
    let isFullScreen: Bool
    var useBiometry: Bool
    var completion: (() -> Void)?
}

protocol CreateOrRestoreWalletHandler {
    func creatingOrRestoringWalletDidComplete(isRestoration: Bool)
}

protocol OnboardingHandler {
    func onboardingDidCancel()
    func onboardingDidComplete()
}

class RootViewModel: CreateOrRestoreWalletHandler, OnboardingHandler {
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
    
    // MARK: - Methods
    init(accountStorage: KeychainAccountStorage) {
        self.accountStorage = accountStorage
        observeAppNotifications()
    }
    
    func reload() {
        if accountStorage.account == nil {
            navigationSubject.accept(.createOrRestoreWallet)
        } else if accountStorage.pinCode == nil ||
                    !Defaults.didSetEnableBiometry ||
                    !Defaults.didSetEnableNotifications
        {
            navigationSubject.accept(.onboarding)
        } else {
            navigationSubject.accept(.main)
        }
    }
    
    func logout() {
        accountStorage.clear()
        Defaults.walletName = [:]
        Defaults.didSetEnableBiometry = false
        Defaults.didSetEnableNotifications = false
        reload()
    }
    
    // MARK: - Handler
    func creatingOrRestoringWalletDidComplete(isRestoration: Bool) {
        self.isRestoration = isRestoration
        navigationSubject.accept(.onboarding)
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
