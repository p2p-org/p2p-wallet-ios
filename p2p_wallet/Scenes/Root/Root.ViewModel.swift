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
    class ViewModel: ViewModelType {
        // MARK: - Nested type
        struct Input {
            
        }
        struct Output {
            let navigationScene: Driver<NavigatableScene?>
            let isLoading: Driver<Bool>
        }
        
        // MARK: - Dependencies
        private let accountStorage: KeychainAccountStorage
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        private var isRestoration = false
        
        let input: Input
        private(set) var output: Output
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let isLoadingSubject = BehaviorRelay<Bool>(value: false)
        
        // MARK: - Initializer
        init(accountStorage: KeychainAccountStorage) {
            self.accountStorage = accountStorage
            
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
                        self.navigationSubject.accept(.createOrRestoreWallet)
                    } else if self.accountStorage.pinCode == nil ||
                                !Defaults.didSetEnableBiometry ||
                                !Defaults.didSetEnableNotifications
                    {
                        self.navigationSubject.accept(.onboarding)
                    } else {
                        self.navigationSubject.accept(.main)
                    }
                }
            }
        }
        
        func logout() {
            accountStorage.clear()
            Defaults.walletName = [:]
            Defaults.didSetEnableBiometry = false
            Defaults.didSetEnableNotifications = false
            reload()
        }
        
        @objc func navigateToMain() {
            reload()
        }
    }
}

extension Root.ViewModel: CreateOrRestoreWalletHandler {
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
}

extension Root.ViewModel: OnboardingHandler {
    func onboardingDidCancel() {
        logout()
    }
    
    @objc func onboardingDidComplete() {
        navigationSubject.accept(.onboardingDone(isRestoration: isRestoration))
    }
}
