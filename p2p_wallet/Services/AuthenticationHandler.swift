//
//  AuthenticationHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/01/2022.
//

import Combine
import Foundation
import UIKit

protocol AuthenticationHandlerType {
    func authenticate(presentationStyle: AuthenticationPresentationStyle?)
    func pauseAuthentication(_ isPaused: Bool)
    var authenticationStatusPublisher: AnyPublisher<AuthenticationPresentationStyle?, Never> { get }
    var isLockedPublisher: AnyPublisher<Bool, Never> { get }
}

final class AuthenticationHandler: ObservableObject, AuthenticationHandlerType {
    // MARK: - Properties

    private var subscriptions = [AnyCancellable]()
    private var timeRequiredForAuthentication = 10 // in seconds
    private var lastAuthenticationTimeStamp = 0
    private var isAuthenticationPaused = false

    // MARK: - Subjects

    @Published private var authenticationStatus: AuthenticationPresentationStyle?
    @Published private var isLocked = false

    init() {
        bind()
    }

    /// Bind subjects
    private func bind() {
        $authenticationStatus
            .drop(while: { $0 == nil })
            .sink { [weak self] status in
                if status == nil {
                    self?.lastAuthenticationTimeStamp = Int(Date().timeIntervalSince1970)
                }
            }
            .store(in: &subscriptions)

        observeAppNotifications()

        $authenticationStatus
            .dropFirst()
            .filter { $0 == nil }
            .map { _ in false }
            .assign(to: \.isLocked, on: self)
            .store(in: &subscriptions)
    }

    private func observeAppNotifications() {
        NotificationCenter.default
            .publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                if self?.authenticationStatus == nil {
                    self?.lastAuthenticationTimeStamp = Int(Date().timeIntervalSince1970)
                    self?.isLocked = true
                }
            }
            .store(in: &subscriptions)

        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if Int(Date().timeIntervalSince1970) >= self.lastAuthenticationTimeStamp + self
                    .timeRequiredForAuthentication
                {
                    self.authenticate(presentationStyle: .login())
                }

                self.isLocked = false
            }
            .store(in: &subscriptions)
    }

    func authenticate(presentationStyle: AuthenticationPresentationStyle?) {
        // check previous and current
        let previous = authenticationStatus
        let current = presentationStyle

        // prevent duplications
        guard (previous == nil && current != nil) || (previous != nil && current == nil)
        else { return }

        // accept current if nil
        if current == nil {
            authenticationStatus = nil
            return
        }

        // show authentication if the condition has been met
        if canPerformAuthentication() {
            authenticationStatus = presentationStyle
            return
        }

        // force a dissmision if not
        else {
            authenticationStatus = nil
            return
        }
    }

    func pauseAuthentication(_ isPaused: Bool) {
        isAuthenticationPaused = isPaused
    }

    var authenticationStatusPublisher: AnyPublisher<AuthenticationPresentationStyle?, Never> {
        $authenticationStatus.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    var isLockedPublisher: AnyPublisher<Bool, Never> {
        $isLocked.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    // MARK: - Helpers

    private func canPerformAuthentication() -> Bool {
        !isAuthenticationPaused
    }
}
