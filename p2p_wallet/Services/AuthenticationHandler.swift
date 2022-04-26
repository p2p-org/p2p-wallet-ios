//
//  AuthenticationHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/01/2022.
//

import Foundation
import RxCocoa
import RxSwift

protocol AuthenticationHandlerType {
    func authenticate(presentationStyle: AuthenticationPresentationStyle?)
    func pauseAuthentication(_ isPaused: Bool)
    var authenticationStatusDriver: Driver<AuthenticationPresentationStyle?> { get }
    var isLockedDriver: Driver<Bool> { get }
}

final class AuthenticationHandler: AuthenticationHandlerType {
    // MARK: - Properties

    private let disposeBag = DisposeBag()
    private var timeRequiredForAuthentication = 10 // in seconds
    private var lastAuthenticationTimeStamp = 0
    private var isAuthenticationPaused = false

    // MARK: - Subjects

    private let authenticationStatusSubject = BehaviorRelay<AuthenticationPresentationStyle?>(value: nil)
    private let isLockedSubject = BehaviorRelay<Bool>(value: false)

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

        authenticationStatusSubject
            .skip(1)
            .filter { $0 == nil }
            .map { _ in true }
            .bind(to: isLockedSubject)
            .disposed(by: disposeBag)
    }

    private func observeAppNotifications() {
        UIApplication.shared.rx
            .applicationWillResignActive
            .subscribe(onNext: { [weak self] _ in
                if self?.authenticationStatusSubject.value == nil {
                    self?.isLockedSubject.accept(true)
                }
            })
            .disposed(by: disposeBag)

        UIApplication.shared.rx.applicationDidBecomeActive
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                guard Int(Date().timeIntervalSince1970) >= self.lastAuthenticationTimeStamp + self
                    .timeRequiredForAuthentication
                else {
                    self.isLockedSubject.accept(false)
                    return
                }
                self.authenticate(presentationStyle: .login())
            })
            .disposed(by: disposeBag)
    }

    func authenticate(presentationStyle: AuthenticationPresentationStyle?) {
        // check previous and current
        let previous = authenticationStatusSubject.value
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

    var isLockedDriver: Driver<Bool> {
        isLockedSubject.asDriver()
    }

    // MARK: - Helpers

    private func canPerformAuthentication() -> Bool {
        !isAuthenticationPaused
    }
}
