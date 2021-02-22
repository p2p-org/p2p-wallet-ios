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
    
    // MARK: - Properties
    private let bag = DisposeBag()
    private let accountStorage: KeychainAccountStorage
    
    // MARK: - Subjects
    let navigationSubject = BehaviorRelay<RootNavigatableScene>(value: .initializing)
    
    // MARK: - Methods
    init(accountStorage: KeychainAccountStorage) {
        self.accountStorage = accountStorage
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
        Defaults.isBiometryEnabled = false
        Defaults.didSetEnableBiometry = false
        Defaults.didSetEnableNotifications = false
        reload()
    }
    
    // MARK: - Handler
    func creatingOrRestoringWalletDidComplete() {
        navigationSubject.accept(.onboarding)
    }
    
    func onboardingDidComplete() {
        navigationSubject.accept(.main)
    }
}
