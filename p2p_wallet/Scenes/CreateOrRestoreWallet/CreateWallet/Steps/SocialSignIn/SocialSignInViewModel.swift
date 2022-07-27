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
}

struct SocialSignInOutput {
    let isLoading: CurrentValueSubject<Bool, Never> = .init(false)
}

class SocialSignInViewModel: ViewModelType {
    private(set) var input: SocialSignInInput = .init()
    private(set) var output: SocialSignInOutput = .init()

    @Injected var authService: AuthService

    let createWalletViewModel: CreateWalletViewModel
    var subscriptions = [AnyCancellable]()

    init(createWalletViewModel: CreateWalletViewModel) {
        self.createWalletViewModel = createWalletViewModel

        // Listen back event
        input.onBack.sink {
            Task {
                try await createWalletViewModel
                    .onboardingStateMachine
                    .accept(event: .signInBack)
            }
        }.store(in: &subscriptions)

        input.onSignInWithApple.sink { [weak self] in
            self?.signIn(type: .apple)
        }.store(in: &subscriptions)

        input.onSignInWithGoogle.sink { [weak self] in
            self?.signIn(type: .google)
        }.store(in: &subscriptions)
    }

    func signIn(type: SocialType) {
        Task {
            output.isLoading.send(true)
            defer { output.isLoading.send(false) }

            do {
                // TODO: pass token id to state machine
                try await Task.sleep(nanoseconds: 1_000_000_000)
                try await authService.auth(with: .social(type))
                try await createWalletViewModel.onboardingStateMachine.accept(
                    event: .signIn(tokenID: "", authProvider: .apple)
                )
            } catch let e {
                print(e)
            }
        }
    }
}
