//
//  AuthenticationHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/01/2022.
//

import Foundation
import Resolver
import Combine
import AnalyticsManager

protocol AuthenticationHandlerType {
    func authenticate(presentationStyle: AuthenticationPresentationStyle?)
    func pauseAuthentication(_ isPaused: Bool)
    var authenticationStatusPublisher: AnyPublisher<AuthenticationPresentationStyle?, Never> { get }
    var authenticationStatus: AuthenticationPresentationStyle? { get }
    var isLockedPublisher: AnyPublisher<Bool, Never> { get }
}

final class AuthenticationHandler: AuthenticationHandlerType {
    // MARK: - Properties

    private var subscriptions = Set<AnyCancellable>()
    private var timeRequiredForAuthentication = 10 // in seconds
    private var lastAuthenticationTimeStamp = 0
    private var isAuthenticationPaused = false
    @Injected private var analyticsManager: AnalyticsManager

    // MARK: - Subjects

    private let authenticationStatusSubject = CurrentValueSubject<AuthenticationPresentationStyle?, Never>(nil)
    private let isLockedSubject = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Computed properties

    var authenticationStatus: AuthenticationPresentationStyle? {
        authenticationStatusSubject.value
    }

    // MARK: - Initializer

    init() {
        bind()
    }

    /// Bind subjects
    private func bind() {
        authenticationStatusSubject
            .drop(while: { $0 == nil })
            .sink(receiveValue: { [weak self] status in
                if status == nil {
                    self?.lastAuthenticationTimeStamp = Int(Date().timeIntervalSince1970)
                } else {
                    self?.analyticsManager.log(event: .login)
                }
            })
            .store(in: &subscriptions)

        observeAppNotifications()

        authenticationStatusSubject
            .dropFirst()
            .filter { $0 == nil }
            .map { _ in false }
            .sink { [weak self] isLocked in
                self?.isLockedSubject.send(isLocked)
            }
            .store(in: &subscriptions)
    }

    private func observeAppNotifications() {
        NotificationCenter.default
            .publisher(for: UIApplication.willResignActiveNotification)
            .sink(receiveValue: { [weak self] _ in
                if self?.authenticationStatusSubject.value == nil {
                    self?.lastAuthenticationTimeStamp = Int(Date().timeIntervalSince1970)
                    self?.isLockedSubject.send(true)
                }
            })
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink(receiveValue: { [weak self] _ in
                guard let self = self else { return }
                if Int(Date().timeIntervalSince1970) >= self.lastAuthenticationTimeStamp + self
                    .timeRequiredForAuthentication
                {
                    self.authenticate(presentationStyle: .login())
                }

                self.isLockedSubject.send(false)
            })
            .store(in: &subscriptions)
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
            authenticationStatusSubject.send(nil)
            return
        }

        // show authentication if the condition has been met
        if canPerformAuthentication() {
            authenticationStatusSubject.send(presentationStyle)
            return
        }

        // force a dissmision if not
        else {
            authenticationStatusSubject.send(nil)
            return
        }
    }

    func pauseAuthentication(_ isPaused: Bool) {
        isAuthenticationPaused = isPaused
    }

    var authenticationStatusPublisher: AnyPublisher<AuthenticationPresentationStyle?, Never> {
        authenticationStatusSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    var isLockedPublisher: AnyPublisher<Bool, Never> {
        isLockedSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    // MARK: - Helpers

    private func canPerformAuthentication() -> Bool {
        !isAuthenticationPaused
    }
}
