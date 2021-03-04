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
    case main
}

protocol CreateOrRestoreWalletHandler {
    func creatingOrRestoringWalletDidComplete()
}

protocol OnboardingHandler {
    func onboardingDidCancel()
    func onboardingDidComplete()
}

class RootViewModel: CreateOrRestoreWalletHandler, OnboardingHandler {
    // MARK: - Constants
    private let timeRequiredForAuthentication = 10 // in seconds
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let accountStorage: KeychainAccountStorage
    
    var isAuthenticating = false
    lazy var lastAuthenticationTimestamp = Int(Date().timeIntervalSince1970) - timeRequiredForAuthentication
    
    var isSessionExpired: Bool {
        Int(Date().timeIntervalSince1970) >= lastAuthenticationTimestamp + timeRequiredForAuthentication
    }
    
    // MARK: - Subjects
    let navigationSubject = BehaviorRelay<RootNavigatableScene>(value: .initializing)
    let authenticationSubject = PublishSubject<Void>()
    
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
    func creatingOrRestoringWalletDidComplete() {
        navigationSubject.accept(.onboarding)
    }
    
    func onboardingDidCancel() {
        logout()
    }
    
    func onboardingDidComplete() {
        navigationSubject.accept(.main)
    }
    
    func observeAppNotifications() {
        UIApplication.shared.rx.applicationDidBecomeActive
            .subscribe(onNext: {[weak self] _ in
                guard let strongSelf = self, !strongSelf.isAuthenticating, strongSelf.isSessionExpired, strongSelf.navigationSubject.value == .main else {return}
                strongSelf.isAuthenticating = true
                strongSelf.authenticationSubject.onNext(())
            })
            .disposed(by: disposeBag)
    }
    
    func secondsLeftToNextAuthentication() -> Int {
        timeRequiredForAuthentication - (Int(Date().timeIntervalSince1970) - Int(lastAuthenticationTimestamp))
    }
}
