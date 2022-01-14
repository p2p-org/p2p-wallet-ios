//
//  AuthenticationHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/01/2022.
//

import Foundation
import RxSwift
import RxCocoa

protocol AuthenticationHandlerType {
    func authenticate(presentationStyle: AuthenticationPresentationStyle?)
    func pauseAuthentication(_ isPaused: Bool)
    var authenticationStatusDriver: Driver<AuthenticationPresentationStyle?> { get }
}

final class AuthenticationHandler: AuthenticationHandlerType {
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var timeRequiredForAuthentication = 10 // in seconds
    private var lastAuthenticationTimeStamp = 0
    private var isAuthenticationPaused = false
    
    // MARK: - Subjects
    private let authenticationStatusSubject = BehaviorRelay<AuthenticationPresentationStyle?>(value: nil)
    
    init() {
        bind()
    }
    
    /// Bind subjects
    private func bind() {
        authenticationStatusSubject
            .skip(while: { $0 == nil })
            .subscribe(onNext: { [weak self] status in
                if status == nil {
                    self?.lastAuthenticationTimeStamp = Int(Date().timeIntervalSince1970)
                }
            })
            .disposed(by: disposeBag)
        
        observeAppNotifications()
    }
    
    private func observeAppNotifications() {
        UIApplication.shared.rx.applicationDidBecomeActive
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                guard Int(Date().timeIntervalSince1970) >= self.lastAuthenticationTimeStamp + self.timeRequiredForAuthentication
                    else { return }
                self.authenticate(presentationStyle: .login())
            })
            .disposed(by: disposeBag)
    }
    
    func authenticate(presentationStyle: AuthenticationPresentationStyle?) {
        // check previous and current
        let previous = self.authenticationStatusSubject.value
        let current = presentationStyle
        
        // prevent duplications
        guard (previous == nil && current != nil) || (previous != nil && current == nil)
            else { return }
        
        // accept current if nil
        if current == nil {
            authenticationStatusSubject.accept(nil)
            return
        }
        
        // show authentication if the condition has been met
        if canPerformAuthentication() {
            authenticationStatusSubject.accept(presentationStyle)
            return
        }
        
        // force a dissmision if not
        else {
            authenticationStatusSubject.accept(nil)
            return
        }
    }
    
    func pauseAuthentication(_ isPaused: Bool) {
        isAuthenticationPaused = isPaused
    }
    
    var authenticationStatusDriver: Driver<AuthenticationPresentationStyle?> {
        authenticationStatusSubject.asDriver()
    }
    
    // MARK: - Helpers
    private func canPerformAuthentication() -> Bool {
        !isAuthenticationPaused
    }
}
