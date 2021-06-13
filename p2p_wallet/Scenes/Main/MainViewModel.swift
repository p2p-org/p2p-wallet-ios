//
//  MainViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/06/2021.
//

import Foundation
import RxSwift
import RxCocoa

class MainViewModel: ViewModelType {
    // MARK: - Nested type
    struct Input {
        let authenticationStatus = PublishRelay<AuthenticationPresentationStyle?>()
    }
    
    struct Output {
        let currentAuthenticationStatus: Driver<AuthenticationPresentationStyle?> // nil if non authentication process is processing
        let isRessetingPasscodeWithSeedPhrases: Driver<Bool>
    }
    
    // MARK: - Dependencies
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var timeRequiredForAuthentication = 10 // in seconds
    private var lastAuthenticationTimeStamp = 0
    private var isAuthenticationPaused = false
    
    let input: Input
    let output: Output
    
    // MARK: - Subjects
    private let authenticationStatusSubject = BehaviorRelay<AuthenticationPresentationStyle?>(value: nil)
    private let isResettingPasscodeWithSeedPhrasesSubject = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Initializer
    init() {
        self.input = Input()
        self.output = Output(
            currentAuthenticationStatus: authenticationStatusSubject
                .asDriver(),
            isRessetingPasscodeWithSeedPhrases: isResettingPasscodeWithSeedPhrasesSubject
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
    func pauseAuthentication(_ isPaused: Bool) {
        isAuthenticationPaused = isPaused
    }
    
    func handleResetPasscodeWithASeedPhrase() {
        isResettingPasscodeWithSeedPhrasesSubject.accept(false)
    }
    
    @objc func resetPinCodeWithASeedPhrase() {
        isResettingPasscodeWithSeedPhrasesSubject.accept(true)
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
        !isAuthenticationPaused && !isResettingPasscodeWithSeedPhrasesSubject.value
    }
}

extension MainViewModel: AuthenticationHandler {
    func authenticate(presentationStyle: AuthenticationPresentationStyle) {
        input.authenticationStatus.accept(presentationStyle)
    }
}
