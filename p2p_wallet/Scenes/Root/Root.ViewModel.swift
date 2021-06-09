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
            let currentAuthenticationStatus: Driver<AuthenticationPresentationStyle?> // nil if non authentication process is processing
            let isLoading: Driver<Bool>
        }
        
        // MARK: - Dependencies
        private let accountStorage: KeychainAccountStorage
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        private var timeRequiredForAuthentication = 10 // in seconds
        private var lastAuthenticationTimeStamp = 0
        private var isRestoration = false
        
        private var isAuthenticationPaused = false
        
        let input: Input
        private(set) var output: Output
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let authenticationStatusSubject = BehaviorRelay<AuthenticationPresentationStyle?>(value: nil)
        private let isLoadingSubject = BehaviorRelay<Bool>(value: false)
        
        // MARK: - Initializer
        init(accountStorage: KeychainAccountStorage) {
            self.accountStorage = accountStorage
            
            self.input = Input()
            self.output = Output(
                navigationScene: navigationSubject
                    .withPrevious()
                    .filter {previous, current in
                        switch (previous, current) {
                        case (.resetPincodeWithASeedPhrase, .main):
                            return false
                        default:
                            return true
                        }
                    }
                    .map {$0.1}
                    .asDriver(onErrorJustReturn: nil),
                currentAuthenticationStatus: authenticationStatusSubject
                    .asDriver(onErrorJustReturn: nil),
                isLoading: isLoadingSubject
                    .asDriver()
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
                .skip(while: {$0 == nil})
                .subscribe(onNext: {[weak self] status in
                    if status == nil {
                        self?.lastAuthenticationTimeStamp = Int(Date().timeIntervalSince1970)
                    }
                })
                .disposed(by: disposeBag)
        }
        
        private func observeAppNotifications() {
            UIApplication.shared.rx.applicationDidBecomeActive
                .subscribe(onNext: {[weak self] _ in
                    guard let strongSelf = self else {return}
                    guard Int(Date().timeIntervalSince1970) >= strongSelf.lastAuthenticationTimeStamp + strongSelf.timeRequiredForAuthentication
                    else {return}
                    strongSelf.input.authenticationStatus.accept(
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
        
        func pauseAuthentication(_ isPaused: Bool) {
            isAuthenticationPaused = isPaused
        }
        
        func handleResetPasscodeWithASeedPhrase() {
            navigationSubject.accept(.main)
        }
        
        @objc func resetPinCodeWithASeedPhrase() {
            navigationSubject.accept(.resetPincodeWithASeedPhrase)
        }
        
        @objc func navigateToMain() {
            reload()
        }
        
        // MARK: - Helpers
        private func mapInputIntoAuthenticationStatus() {
            input.authenticationStatus
                .filter { [weak self] status in
                    let previous = self?.authenticationStatusSubject.value
                    let current = status
                    return (previous == nil && current != nil) || (previous != nil && current == nil)
                }
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
                && !isAuthenticationPaused
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
