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
            let authenticationStatus = PublishRelay<AuthenticationPresentationStyle?>()
        }
        struct Output {
            let navigationScene: Driver<NavigatableScene?>
            fileprivate(set) var currentAuthenticationStatus: Driver<AuthenticationPresentationStyle?> // nil if non authentication process is processing
        }
        
        // MARK: - Dependencies
        private let accountStorage: KeychainAccountStorage
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        private var timeRequiredForAuthentication = 10 // in seconds
        private var lastAuthenticationTimeStamp = 0
        private var isRestoration = false
        
        let input: Input
        private(set) var output: Output
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let authenticationStatusSubject = BehaviorRelay<AuthenticationPresentationStyle?>(value: nil)
        
        // MARK: - Initializer
        init(accountStorage: KeychainAccountStorage) {
            self.accountStorage = accountStorage
            
            self.input = Input()
            self.output = Output(
                navigationScene: navigationSubject
                    .asDriver(onErrorJustReturn: nil),
                currentAuthenticationStatus: authenticationStatusSubject
                    .asDriver(onErrorJustReturn: nil)
            )
            
            bind()
        }
        
        /// Bind subjects
        private func bind() {
            bindInputIntoSubjects()
            bindSubjectsIntoSubjects()
            observeAppNotifications()
        }
        
        private func bindInputIntoSubjects() {
            mapInputIntoAuthenticationStatus()
        }
        
        private func bindSubjectsIntoSubjects() {
            authenticationStatusSubject
                .subscribe(onNext: {[weak self] status in
                    if status != nil {
                        self?.lastAuthenticationTimeStamp = Int(Date().timeIntervalSince1970)
                    }
                })
                .disposed(by: disposeBag)
        }
        
        private func observeAppNotifications() {
            UIApplication.shared.rx.applicationDidBecomeActive
                .subscribe(onNext: {[weak self] _ in
                    self?.input.authenticationStatus.accept(
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
        
        // MARK: - Actions
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
        
        // MARK: - Helpers
        private func mapInputIntoAuthenticationStatus() {
            input.authenticationStatus
                .withPrevious()
                .filter {status in
                    let previous = status.0
                    let current = status.1
                    return (previous == nil && current != nil) || (previous != nil && current == nil)
                }
                .map {$0.1}
                .map {[weak self] status -> AuthenticationPresentationStyle? in
                    // dismiss
                    if status == nil {return nil}

                    // show authentication if the condition has been met
                    if self?.canPerformAuthentication() == true {
                        return status
                    } else {
                        return nil
                    }
                }
                .bind(to: authenticationStatusSubject)
                .disposed(by: disposeBag)
        }
        
        private func canPerformAuthentication() -> Bool {
            navigationSubject.value == .main // disable authentication on other scenes
                && (Int(Date().timeIntervalSince1970) >= lastAuthenticationTimeStamp + timeRequiredForAuthentication)
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

extension Root.ViewModel: AuthenticationHandler {
    func authenticate(presentationStyle: AuthenticationPresentationStyle) {
        input.authenticationStatus.accept(presentationStyle)
    }
}
