// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding
import Resolver

class SocialSignInAccountHasBeenUsedViewModel: NSObject, ViewModelType {
    struct Input {
        let onBack: PassthroughSubject<Void, Never> = .init()
        let onInfo: PassthroughSubject<Void, Never> = .init()

        let useAnotherAccount: PassthroughSubject<Void, Never> = .init()
        let restoreThisWallet: PassthroughSubject<Void, Never> = .init()

        fileprivate let isLoading: CurrentValueSubject<Bool, Never> = .init(false)
    }

    struct Output {
        let emailAddress: AnyPublisher<String, Never>
        let signInProvider: AnyPublisher<SignInProvider, Never>
        let isLoading: AnyPublisher<Bool, Never>
    }

    var input: Input = .init()
    var output: Output

    var subscriptions = [AnyCancellable]()

    @Injected var authService: AuthService
    @Injected var notificationService: NotificationService

    let createWalletViewModel: CreateWalletViewModel

    init(createWalletViewModel: CreateWalletViewModel, email: String, signInProvider: SignInProvider) {
        self.createWalletViewModel = createWalletViewModel
        output = .init(
            emailAddress: CurrentValueSubject(email).eraseToAnyPublisher(),
            signInProvider: CurrentValueSubject(signInProvider).eraseToAnyPublisher(),
            isLoading: input.isLoading.eraseToAnyPublisher()
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

        input.useAnotherAccount.sink { [weak self] in self?.userAnotherGoogleAccount(signInProvider: signInProvider) }
            .store(in: &subscriptions)

        input.restoreThisWallet
            .sink { [weak self] in self?.restoreWallet(signInProvider: signInProvider, email: email) }
            .store(in: &subscriptions)
    }

    func userAnotherGoogleAccount(signInProvider _: SignInProvider) {
        Task {
            input.isLoading.send(true)
            defer { input.isLoading.send(false) }

            do {
                let signInResult = try await authService.socialSignIn(.google)
                try await createWalletViewModel.onboardingStateMachine
                    .accept(
                        event: .signIn(
                            tokenID: signInResult.tokenID, authProvider: .google,
                            email: signInResult.email
                        )
                    )
            } catch {
                DispatchQueue.main.async {
                    self.notificationService.showInAppNotification(.error(error))
                }
            }
        }
    }

    func restoreWallet(signInProvider: SignInProvider, email: String) {
        Task {
            input.isLoading.send(true)
            defer { input.isLoading.send(false) }

            do {
                try await createWalletViewModel.onboardingStateMachine
                    .accept(
                        event: .signInRerouteToRestore(authProvider: signInProvider, email: email)
                    )
            } catch {
                DispatchQueue.main.async {
                    self.notificationService.showInAppNotification(.error(error))
                }
            }
        }
    }
}
