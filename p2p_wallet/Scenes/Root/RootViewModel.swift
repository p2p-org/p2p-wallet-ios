//
//  RootViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import UIKit
import RxSwift
import RxCocoa

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
    func onboardingDidComplete()
}

class RootViewModel: CreateOrRestoreWalletHandler, OnboardingHandler {
    // MARK: - Constants
    let timeRequiredForAuthentication: Double = 10 // in seconds
    
    // MARK: - Properties
    private let bag = DisposeBag()
    private let accountStorage: KeychainAccountStorage
    
    var shouldShowLocalAuth = true
    var localAuthVCShown = false
    private var shouldUpdateBalance = false
    private(set) var timestamp = Date().timeIntervalSince1970
    
    // MARK: - Subjects
    let navigationSubject = BehaviorRelay<RootNavigatableScene>(value: .initializing)
    let authenticationSubject = PublishSubject<Void>()
    
    // MARK: - Methods
    init(accountStorage: KeychainAccountStorage) {
        self.accountStorage = accountStorage
    }
    
    func observeAppNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidActive), name: UIScene.didActivateNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIScene.didEnterBackgroundNotification, object: nil)
    }
    
    func reload() {
        if accountStorage.account == nil {
            shouldShowLocalAuth = false
            navigationSubject.accept(.createOrRestoreWallet)
        } else if accountStorage.pinCode == nil ||
                    !Defaults.didSetEnableBiometry ||
                    !Defaults.didSetEnableNotifications
        {
            shouldShowLocalAuth = false
            navigationSubject.accept(.onboarding)
        } else {
            shouldShowLocalAuth = true
            navigationSubject.accept(.main)
        }
    }
    
    func rescheduleAuth() {
        timestamp = Date().timeIntervalSince1970
    }
    
    // MARK: - Application notifications
    @objc func appDidActive() {
        // check authentication
        let newTimestamp = Date().timeIntervalSince1970
        timestamp = newTimestamp - timeRequiredForAuthentication
        
        if shouldShowLocalAuth && !localAuthVCShown && timestamp + timeRequiredForAuthentication <= newTimestamp,
           navigationSubject.value == .main
        {
            
            timestamp = newTimestamp
            authenticationSubject.onNext(())
        }
        
        // update balance
        if shouldUpdateBalance {
            DependencyContainer.shared.sharedMyWalletsVM.reload()
            shouldUpdateBalance = false
        }
    }
    
    @objc func appDidEnterBackground() {
        shouldUpdateBalance = true
    }
    
    // MARK: - Handler
    func creatingOrRestoringWalletDidComplete() {
        navigationSubject.accept(.onboarding)
    }
    
    func onboardingDidComplete() {
        navigationSubject.accept(.main)
    }
}
