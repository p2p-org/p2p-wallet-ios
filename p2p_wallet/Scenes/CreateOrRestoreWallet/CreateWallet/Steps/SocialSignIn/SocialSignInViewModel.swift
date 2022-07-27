// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Resolver

struct SocialSignInInput {
    let onBack: PassthroughSubject<Void, Never> = .init()
    let onTermAndCondition: PassthroughSubject<Void, Never> = .init()
    let onInfo: PassthroughSubject<Void, Never> = .init()
    let onSignInWithApple: PassthroughSubject<Void, Never> = .init()
    let onSignInWithGoogle: PassthroughSubject<Void, Never> = .init()

    fileprivate let isLoading: CurrentValueSubject<Bool, Never> = .init(false)
}

struct SocialSignInOutput {
    let isLoading: AnyPublisher<Bool, Never>
    let onInfo: AnyPublisher<Void, Never>
}

class SocialSignInViewModel: NSObject, ViewModelType {
    private(set) var input: SocialSignInInput = .init()
    private(set) var output: SocialSignInOutput

    @Injected var authService: AuthService
    @Injected var notificationService: NotificationService

    let createWalletViewModel: CreateWalletViewModel
    var subscriptions = [AnyCancellable]()

    init(createWalletViewModel: CreateWalletViewModel) {
        self.createWalletViewModel = createWalletViewModel

        output = .init(
            isLoading: input.isLoading.eraseToAnyPublisher(),
            onInfo: input.onTermAndCondition.eraseToAnyPublisher()
        )

        super.init()

        // Listen back event
        input.onBack.sink {
            Task {
                try await createWalletViewModel
                    .onboardingStateMachine
                    .accept(event: .signInBack)
            }
        }.store(in: &subscriptions)

        // Sign in with apple event
        input.onSignInWithApple.sink { [weak self] in
            self?.signIn(type: .apple)
        }.store(in: &subscriptions)

        // Sign in with google event
        input.onSignInWithGoogle.sink { [weak self] in
            self?.signIn(type: .google)
        }.store(in: &subscriptions)
    }

    func signIn(type: SocialType) {
        Task {
            input.isLoading.send(true)
            defer { input.isLoading.send(false) }

            do {
                // TODO: pass token id to state machine
                let signInResult = try await authService.socialSignIn(type)
                try await createWalletViewModel.onboardingStateMachine.accept(
                    event: .signIn(tokenID: signInResult.tokenID, authProvider: .apple, email: signInResult.email)
                )
            } catch let e {
                DispatchQueue.main.async {
                    self.notificationService.showInAppNotification(.error(e))
                }
            }
        }
    }
}
